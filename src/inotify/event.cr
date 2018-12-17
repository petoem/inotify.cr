module Inotify
  struct Event
    property name, path : String
    property mask, cookie : UInt32
    property type : Type
    @is_dir : Bool

    def directory?
      @is_dir
    end

    def initialize(@name : String, @path : String, @mask : UInt32, @cookie : UInt32, @is_dir : Bool, @type : Type)
    end

    enum Type
      CREATE
      MODIFY
      MOVE
      MOVE_SELF
      DELETE
      DELETE_SELF
      UNKNOWN

      def self.parse_mask(mask : UInt32) : Type
        event = Type::UNKNOWN
        event = Type::MODIFY if LibInotify::IN_MODIFY & mask != 0
        event = Type::MOVE if LibInotify::IN_MOVE & mask != 0
        event = Type::CREATE if LibInotify::IN_CREATE & mask != 0
        event = Type::DELETE if LibInotify::IN_DELETE & mask != 0
        event = Type::DELETE_SELF if LibInotify::IN_DELETE_SELF & mask != 0
        event = Type::MOVE_SELF if LibInotify::IN_MOVE_SELF & mask != 0
        event
      end
    end
  end
end
