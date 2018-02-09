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

    def initialize(@path : String, @recursive : Bool = false, &block : Event ->)
      @fd = LibInotify.init LibC::O_NONBLOCK
      raise "inotify init failed" if @fd < 0
      @io = IO::FileDescriptor.new(@fd)
      LOG.debug "inotify init"

      if File.file? @path
        wd = LibInotify.add_watch(@fd, @path, DEFAULT_WATCH_FLAG)
        raise "inotify add_watch failed" if wd == -1
        LOG.debug "inotify add_watch file #{wd} #{path}"
        @watch_list[wd] = WatchInfo.new(wd, @path, false)
      end
      watch @path if File.directory?(@path)

      @event_channel = Channel(Event).new
      @on_event_callback = block
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
            # unwatch event_ptr.value.wd if event.event_type.delete_self?
            pos += 16 + event_ptr.value.len
          end
          pos = 0
        end
      end
    end

    private def wait_for_event
      spawn do
        loop { @on_event_callback.call(@event_channel.receive) }
      end
    end

    private def watch(path : String)
      wd = LibInotify.add_watch(@fd, path, DEFAULT_WATCH_FLAG)
      raise "inotify add_watch failed" if wd == -1
      LOG.debug "inotify add_watch directory #{wd} #{path}"
      @watch_list[wd] = WatchInfo.new(wd, path, true)
      unless Dir.empty?(path) || !@recursive
        Dir.each_child(path) { |child| watch(File.join(path, child)) if File.directory?(File.join(path, child)) }
      end
    end

    private def unwatch
      @watch_list.each_key do |key|
        unwatch key
      end
    end

    private def unwatch(wd : LibC::Int)
      LibInotify.rm_watch(@fd, wd)
      @watch_list.delete wd
    end

    def finalize
      @io.close
    end
  end
end
