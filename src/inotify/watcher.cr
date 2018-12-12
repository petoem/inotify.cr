module Inotify
  struct WatchInfo
    getter wd : Int32
    getter path : String
    getter absolute_path : String
    @is_dir : Bool

    def initialize(@wd : Int32, @path : String, @is_dir : Bool)
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

    def initialize(@recursive : Bool = false)
      @fd = LibInotify.init LibC::O_NONBLOCK
      raise Errno.new "inotify init failed" if @fd == -1
      LOG.debug "inotify init"
      @io = IO::FileDescriptor.new(@fd)
      LOG.debug "inotify IO created"

      @event_channel = Channel(Event).new
      wait_for_event
      enable
    end

    def enable
      unless @enabled
        @enabled = true
        spawn lurk
      end
    end

    def disable
      @enabled = false
    end

    private def lurk
      pos = 0
      while @enabled
        slice = Slice(UInt8).new(LibInotify::BUF_LEN)
        LOG.debug "waiting for event data"
        bytes_read = @io.read(slice)
        raise "inotify read() failed" if bytes_read == 0
        LOG.debug "received event data"
        if bytes_read > 0
          while pos < bytes_read
            sub_slice = slice + pos
            event_ptr = sub_slice.pointer(sub_slice.size).as(LibInotify::Event*)
            # Read LibInotify::Event.name
            slice_event_name = sub_slice[16, event_ptr.value.len]
            event_name = String.new(slice_event_name.pointer(slice_event_name.size).as(LibC::Char*))
            # Fix empty event_name when file is being watched
            wl = @watch_list[event_ptr.value.wd]
            event_name = File.basename(wl.absolute_path) unless wl.directory?

            triggerer_is_dir = 0 != event_ptr.value.mask & LibInotify::IN_ISDIR
            event_type = EventType.parse_mask(event_ptr.value.mask)
            # Build final event object
            event = Event.new(event_name,
              wl.path,
              event_ptr.value.mask,
              event_ptr.value.cookie,
              triggerer_is_dir,
              event_type)

            @event_channel.send event
            watch File.join(event.path, event.name) if event.directory? && event.event_type.create? && @recursive
            # Watch was removed
            @watch_list.delete event_ptr.value.wd if 0 != event_ptr.value.mask & LibInotify::IN_IGNORED
            pos += 16 + event_ptr.value.len
          end
          pos = 0
        end
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

    # TODO: block with no event argument ????
    def on_event(&block : Event ->)
      @event_callbacks.push block
    end

    def watch(path : String, mask = DEFAULT_WATCH_FLAG)
      wd = LibInotify.add_watch(@fd, path, mask)
      raise Errno.new "inotify add_watch failed" if wd == -1
      LOG.debug "inotify add_watch #{wd} #{path}"
      if is_dir = File.directory? path
        @watch_list[wd] = WatchInfo.new wd, path, is_dir
        unless Dir.empty?(path) || !@recursive
          Dir.each_child(path) { |child| watch(File.join(path, child)) if File.directory?(File.join(path, child)) }
        end
      else
        @watch_list[wd] = WatchInfo.new wd, path, false
      end
    end

    def unwatch(path : String)
      @watch_list.each_value do |info|
        unwatch info.wd if info.path == path
      end
    end

    def unwatch(wd : LibC::Int)
      status = LibInotify.rm_watch(@fd, wd)
      if status == -1
        case Errno.value
        when Errno::EBADF then raise IO::Error.new "fd is not a valid file descriptor"
        when Errno::EINVAL then raise Errno.new "The watch descriptor wd is not valid; or fd is not an inotify file descriptor"
        else
          raise Errno.new "inotify rm_watch failed"
        end
      end
    end

    def finalize
      @io.close
    end
  end
end
