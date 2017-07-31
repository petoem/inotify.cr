require "./inotify/*"

module Inotify
  def self.watch(path : String, recursive : Bool = false, &block : Event ->)
    # TODO: check if platform is linux
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
