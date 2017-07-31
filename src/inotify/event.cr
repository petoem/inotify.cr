module Inotify
  struct Event
    property name, path : String
    property mask, cookie : UInt32
    property event_type : EventType
    @is_dir : Bool

    def directory?
      @is_dir
    end

    def initialize(@name : String, @path : String, @mask : UInt32, @cookie : UInt32, @is_dir : Bool, @event_type : EventType)
    end
  end

  enum EventType
    CREATE
    MODIFY
    MOVE
    MOVE_SELF
    DELETE
    DELETE_SELF
    UNKNOWN

    def self.parse_mask(mask : UInt32) : EventType
      event = EventType::UNKNOWN
      event = EventType::MODIFY if LibInotify::IN_MODIFY & mask != 0
      event = EventType::MOVE if LibInotify::IN_MOVE & mask != 0
      event = EventType::CREATE if LibInotify::IN_CREATE & mask != 0
      event = EventType::DELETE if LibInotify::IN_DELETE & mask != 0
      event = EventType::DELETE_SELF if LibInotify::IN_DELETE_SELF & mask != 0
      event = EventType::MOVE_SELF if LibInotify::IN_MOVE_SELF & mask != 0
      event
    end
  end
end
