require "./inotify/version"

{% skip_file unless flag?(:linux) %}

require "./inotify/lib_inotify"
require "./inotify/settings"
require "./inotify/event"
require "./inotify/watcher"

module Inotify
  # Same as `Inotify::Watcher.new`.
  def self.watcher(recursive : Bool = false) : Inotify::Watcher
    Watcher.new(recursive)
  end

  # All-in-one method to create inotify instance to watch one path.
  def self.watch(path : String, recursive : Bool = false, &block : Inotify::Event ->) : Inotify::Watcher
    inotify = Inotify.watcher recursive
    inotify.on_event &block
    inotify.watch path
    inotify
  end
end
