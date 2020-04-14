module Inotify
  private struct WatchInfo
    getter wd : Int32
    getter path : String
    getter absolute_path : String
    getter mask : Int32
    @is_dir : Bool

    def initialize(@wd : Int32, @path : String, @is_dir : Bool, @mask : Int32)
      @absolute_path = File.expand_path(@path)
    end

    def directory?
      @is_dir
    end
  end

  class Watcher
    @enabled : Bool = false
    @watch_list = {} of LibC::Int => WatchInfo
    @event_callbacks = [] of Proc(Event, Nil)

    # Creates a new inotify instance and starts reading from the event queue.
    # Optional: Set *recursive* to `true` to automatically watch all new subdirectories.
    def initialize(@recursive : Bool = false)
      fd = LibInotify.init LibC::O_NONBLOCK
      raise Error.from_errno "inotify init failed" if fd == -1
      LOG.debug "inotify init"
      @io = IO::FileDescriptor.new fd
      LOG.debug "inotify IO created"

      @event_channel = Channel(Event).new
      @enabled = true
      wait_for_event
      spawn lurk
    end

    private def lurk # ameba:disable Metrics/CyclomaticComplexity
      pos = 0
      while @enabled
        slice = Slice(UInt8).new(LibInotify::BUF_LEN)
        LOG.debug "waiting for event data"
        bytes_read = @io.read(slice)
        raise Error.from_errno "inotify read() failed" if bytes_read == -1
        LOG.debug "received event data"
        if bytes_read > 0
          while pos < bytes_read
            sub_slice = slice + pos
            event_ptr = sub_slice.to_unsafe.as(LibInotify::Event*)
            # Read LibInotify::Event.name
            event_name = if event_ptr.value.len != 0
                           slice_event_name = sub_slice[16, event_ptr.value.len]
                           String.new(slice_event_name.to_unsafe.as(LibC::Char*))
                         else
                           nil
                         end
            # Handle edge case where watch descriptor is not known
            wl = @watch_list[event_ptr.value.wd]?
            # Build final event object
            event = Event.new(event_name,
              wl.try &.path,
              event_ptr.value.mask,
              event_ptr.value.cookie,
              event_ptr.value.wd)

            # Watch new subdirectories (`event.name` can not be `nil` if `event.directory?`)
            if (name = event.name) && (path = event.path) && event.directory? && event.type.create? && @recursive
              watch File.join(path, name)
            end
            # Watch was removed
            @watch_list.delete event_ptr.value.wd if event.type.ignored?
            # Finally send out the event
            @event_channel.send event
            pos += 16 + event_ptr.value.len
          end
          pos = 0
        end
      end
    rescue ex
      if @enabled
        raise ex
      elsif !(ex.is_a?(IO::Error) && ex.message == "Closed stream")
        # Ignore the `Closed stream (IO::Error)` when watcher is closed
        raise ex
      end
    end

    private def wait_for_event
      spawn do
        loop do
          event = @event_channel.receive
          @event_callbacks.each do |proc|
            proc.call event
          end
        end
      end
    end

    # Attach a `&block` to the instance, this will receive all events.
    def on_event(&block : Event ->)
      @event_callbacks.push block
      nil
    end

    # Removes all event handlers added with `#on_event`.
    def clear_event_handlers
      @event_callbacks.clear
      nil
    end

    # Adds a new watch, or modifies an existing watch, for the *path* specified.
    # Optional: The events to be monitored can be specified in the *mask* bit-mask argument.
    def watch(path : String, mask = DEFAULT_WATCH_FLAG)
      wd = LibInotify.add_watch(@io.fd, path, mask)
      raise Error.from_errno "inotify add_watch failed" if wd == -1
      LOG.debug "inotify add_watch #{wd} #{path}"
      if is_dir = File.directory? path
        @watch_list[wd] = WatchInfo.new wd, path, is_dir, mask
        # ameba:disable Style/NegatedConditionsInUnless
        unless Dir.empty?(path) || !@recursive
          Dir.each_child(path) { |child| watch(File.join(path, child)) if File.directory?(File.join(path, child)) }
        end
      else
        @watch_list[wd] = WatchInfo.new wd, path, false, mask
      end
    end

    # Removes an item from an inotify watch list based on its *path*. Returns `true` on success.
    # NOTE: *path* is case sensitive and has to be an exact match, to what was passed into `#watch`.
    def unwatch(path : String)
      @watch_list.each_value do |info|
        return unwatch info.wd if info.path == path
      end
      false
    end

    # Removes an item from an inotify watch list based on its watch descriptor *wd*.
    # Returns `true` on success, otherwise raises.
    def unwatch(wd : LibC::Int)
      status = LibInotify.rm_watch(@io.fd, wd)
      if status == -1
        case Errno.value
        when Errno::EBADF  then raise IO::Error.new "fd is not a valid file descriptor"
        when Errno::EINVAL then raise Error.from_errno "The watch descriptor wd is not valid; or fd is not an inotify file descriptor"
        else
          raise Error.from_errno "inotify rm_watch failed"
        end
      end
      LOG.debug "inotify rm_watch #{wd}"
      true
    end

    # Returns all paths that are currently being watched.
    def watching : Array(String)
      @watch_list.values.map(&.path)
    end

    # Closes file descriptor referring to the inotify instance.
    def close
      @enabled = false
      @io.close
      LOG.debug "file descriptor referring to inotify instance closed"
    end

    def finalize
      close
    end
  end

  class Error < Exception
    include SystemError
  end
end
