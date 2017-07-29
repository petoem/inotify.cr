module Inotify
  struct Event
    property name, path : String
    property mask, cookie : UInt32

    def initialize(@name : String, @path : String, @mask : UInt32, @cookie : UInt32)
    end
  end
end
