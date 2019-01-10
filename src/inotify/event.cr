module Inotify
  # Represents an `inotify_event` structure.
  struct Event
    # Name of the file or directory that triggered the event. Always `nil` if `#wd` is associated with a file.
    property name : String?
    # Watched *path* this event occurred against, may be `nil` if we don't have the associated `WatchInfo`.
    property path : String?
    # Contains bits that describe the event that occurred.
    property mask : UInt32
    # Is a unique integer that connects related events.
    property cookie : UInt32
    # Watch descriptor *wd* identifies the watch for which this event occurred.
    getter wd : Int32
    # `Type` of the event.
    getter type : Type

    # Returns if the event occurred against a directory.
    def directory?
      type_is? LibInotify::IN_ISDIR
    end

    # Returns whether the *bits* are set in `#mask`. Can be used with constants in `LibInotify`.
    # Useful when `#type` is `UNKNOWN`.
    def type_is?(bits)
      bits & @mask != 0
    end

    # Creates a new event.
    def initialize(@name : String?, @path : String?, @mask : UInt32, @cookie : UInt32, @wd : Int32)
      @type = Type.parse @mask
    end

    # Event types corresponding to the ones in `LibInotify`.
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

      # Parses the given *mask* and returns the event type or `UNKNOWN`.
      def self.parse(mask : UInt32) : self
        Type.each do |member, bits|
          return member if bits & mask != 0
        end
        Type::UNKNOWN
      end
    end
  end
end
