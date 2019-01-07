require "./inotify/version"

{% skip_file unless flag?(:linux) %}

require "./inotify/lib_inotify"
require "./inotify/settings"
require "./inotify/event"
require "./inotify/watcher"

module Inotify
  def self.watcher(recursive : Bool = false) : Inotify::Watcher
    Watcher.new(recursive)
  end

  def self.watch(path : String, recursive : Bool = false, &block : Inotify::Event ->) : Inotify::Watcher
    inotify = Inotify.watcher recursive
    inotify.on_event &block
    inotify.watch path
    inotify
  end
end
