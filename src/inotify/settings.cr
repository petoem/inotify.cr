require "log"

module Inotify
  Log                = ::Log.for("inotify")
  DEFAULT_WATCH_FLAG = LibInotify::IN_MOVE | LibInotify::IN_MOVE_SELF | LibInotify::IN_MODIFY | LibInotify::IN_CREATE | LibInotify::IN_DELETE | LibInotify::IN_DELETE_SELF
end
