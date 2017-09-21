require "./inotify/version"
require "./inotify/event"
require "./inotify/fallback"
require "./inotify/settings"

{% if flag?(:linux) %}
  require "./inotify/lib_inotify"
  require "./inotify/watcher"
{% else %}
  module Inotify
    alias Watcher = Fallback
  end
{% end %}

module Inotify
  def self.watch(path : String, recursive : Bool = false, &block : Event ->)
    Watcher.new(path, recursive, &block)
  end
end

class File
  def self.watch(path : String, &block : Inotify::Event ->)
    Inotify.watch(path, false, &block)
  end
end

class Dir
  def self.watch(path : String, recursive : Bool = false, &block : Inotify::Event ->)
    Inotify.watch(path, recursive, &block)
  end
end
