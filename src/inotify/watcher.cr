module Inotify
  class Watcher
    @enabled : Bool = false

    def initialize(@path : String, @poll_interval : UInt32 = 1_u32, &block : Event ->)
      @fd = LibInotify.init LibC::O_NONBLOCK
      raise "inotify init failed" if @fd < 0
      @io = IO::FileDescriptor.new(@fd)
      LOG.debug "inotify init"

      @wd = LibInotify.add_watch(@fd, @path, LibInotify::IN_MODIFY | LibInotify::IN_CREATE | LibInotify::IN_DELETE)
      raise "inotify add_watch failed" if @wd == -1
      LOG.debug "inotify add_watch"

      @event_channel = Channel(Event).new
      @on_event_callback = block
      wait_for_event
      enable
    end

    def enable
      unless @enabled
        @enabled = true
        spawn watch
      end
    end

    def disable
      @enabled = false
    end

    private def watch
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

            slice_event_name = sub_slice[16, event_ptr.value.len]
            event_name = String.new(slice_event_name.pointer(slice_event_name.size).as(LibC::Char*))

            event = Event.new(event_name, File.join(@path, event_name), event_ptr.value.mask, event_ptr.value.cookie)
            @event_channel.send event
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

    private def unwatch
      LibInotify.rm_watch(@fd, @wd)
    end

    def finalize
      LibInotify.rm_watch(@fd, @wd)
      @io.close
    end
  end
end
