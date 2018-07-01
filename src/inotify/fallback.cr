module Inotify
  class Fallback
    @file_index : Hash(String, File::Info)

    def initialize(@path : String, @recursive : Bool = false, &block : Event ->)
      LOG.debug "using fallback"
      LOG.debug "fallback watch path #{@path}"
      @file_index = create_index
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
      while @enabled
        index = create_index
        # Check for create event
        created = index.keys - @file_index.keys
        created.each do |create|
          is_dir = index[create].directory?
          event_name = create
          event_name = File.basename(create) unless is_dir
          @event_channel.send Event.new(
            event_name,
            create,
            0_u32,
            0_u32,
            is_dir,
            EventType::CREATE
          )
        end
        # Check for delete event
        deleted = @file_index.keys - index.keys
        deleted.each do |del|
          is_dir = @file_index[del].directory?
          event_name = del
          event_name = File.basename(del) unless is_dir
          @event_channel.send Event.new(
            event_name,
            del,
            0_u32,
            0_u32,
            is_dir,
            EventType::DELETE
          )
        end
        # Check for modify event
        index_list = index.keys & @file_index.keys
        index_list.each do |child|
          if index[child].modification_time.to_s("%Y%m%d%H%M%S") != @file_index[child].modification_time.to_s("%Y%m%d%H%M%S")
            is_dir = index[child].directory?
            event_name = child
            event_name = File.basename(child) unless is_dir
            @event_channel.send Event.new(
              event_name,
              child,
              0_u32,
              0_u32,
              is_dir,
              EventType::MODIFY
            )
          end
        end
        @file_index = index
        sleep FALLBACK_SCAN_INTERVAL
      end
    end

    private def wait_for_event
      spawn do
        loop { @on_event_callback.call(@event_channel.receive) }
      end
    end

    private def create_index
      LOG.debug "fallback create index"
      index = {} of String => File::Info
      Dir.glob @path do |child|
        index[child] = File.info(child)
        LOG.debug "fallback found #{child}"
      end
      index
    end
  end
end
