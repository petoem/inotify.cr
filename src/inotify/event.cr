module Inotify
  struct Event
    property name, path : String
    property mask, cookie : UInt32
    property type : Type

    def directory?
      type_is? LibInotify::IN_ISDIR
    end

    def type_is?(bits)
      bits & @mask != 0
    end

    def initialize(@name : String, @path : String, @mask : UInt32, @cookie : UInt32)
      @type = Type.parse @mask
    end

    enum Type
      UNKNOWN       = 0x00000000
      ACCESS        = LibInotify::IN_ACCESS
      MODIFY        = LibInotify::IN_MODIFY
      ATTRIB        = LibInotify::IN_ATTRIB
      CLOSE_WRITE   = LibInotify::IN_CLOSE_WRITE
      CLOSE_NOWRITE = LibInotify::IN_CLOSE_NOWRITE
      OPEN          = LibInotify::IN_OPEN
      MOVED_FROM    = LibInotify::IN_MOVED_FROM
      MOVED_TO      = LibInotify::IN_MOVED_TO
      CREATE        = LibInotify::IN_CREATE
      DELETE        = LibInotify::IN_DELETE
      DELETE_SELF   = LibInotify::IN_DELETE_SELF
      MOVE_SELF     = LibInotify::IN_MOVE_SELF
      CLOSE         = LibInotify::IN_CLOSE
      MOVE          = LibInotify::IN_MOVE
      UNMOUNT       = LibInotify::IN_UNMOUNT
      Q_OVERFLOW    = LibInotify::IN_Q_OVERFLOW
      IGNORED       = LibInotify::IN_IGNORED

      def self.parse(mask : UInt32) : self
        Type.each do |member, bits|
          return member if bits & mask != 0
        end
        Type::UNKNOWN
      end
    end
  end
end
