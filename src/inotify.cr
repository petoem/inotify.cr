require "./inotify/version"
require "./inotify/event"
require "./inotify/fallback"

{% skip_file unless flag?(:linux) %}

require "./inotify/lib_inotify"
require "./inotify/settings"
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

class File
  def self.watch(path : String, &block : Inotify::Event ->) : Inotify::Watcher
    inotify = Inotify.watcher
    inotify.on_event &block
    inotify.watch path
    inotify
  end

  def watch(&block : Inotify::Event ->) : Inotify::Watcher
    File.watch @path, &block
  end
end

class Dir
  def self.watch(path : String, recursive : Bool = false, &block : Inotify::Event ->) : Inotify::Watcher
    inotify = Inotify.watcher recursive
    inotify.on_event &block
    inotify.watch path
    inotify
  end

  def watch(recursive : Bool = false, &block : Inotify::Event ->) : Inotify::Watcher
    Dir.watch @path, recursive, &block
  end
end
