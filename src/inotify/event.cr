module Inotify
  struct Event
    property name, path : String
    property mask, cookie : UInt32
    property type : Type
    @is_dir : Bool

    def directory?
      @is_dir
    end

    def type_is?(bits)
      bits & @mask != 0
    end

    def initialize(@name : String, @path : String, @mask : UInt32, @cookie : UInt32, @is_dir : Bool)
      @type = Type.parse @mask
    end

    @[Flags]
    enum Type
      UNKNOWN = 0
      ACCESS
      MODIFY
      ATTRIB
      CLOSE_WRITE
      CLOSE_NOWRITE
      OPEN
      MOVED_FROM
      MOVED_TO
      CREATE
      DELETE
      DELETE_SELF
      MOVE_SELF
      CLOSE = (CLOSE_WRITE | CLOSE_NOWRITE)
      MOVE = (MOVED_FROM | MOVED_TO)
      
      def self.parse(mask : UInt32) : self
        Type.each do |member, bits|
          return member if bits & mask != 0
        end
        Type::UNKNOWN
      end

      # Patch that `Type::UNKNOWN.unknown?` returns `false` because `@[Flags]` attribute creates `None` member with value `0`.
      def unknown?
        self == Type::UNKNOWN
      end
    end
  end
end
