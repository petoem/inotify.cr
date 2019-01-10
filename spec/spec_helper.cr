require "spec"
require "../src/inotify"

TIME       = 500.milliseconds
TEST_DIR   = "./spec/test"
TEST_FILE  = "#{TEST_DIR}/file.txt"
EVENT_CHAN = Channel(Inotify::Event).new

alias Type = Inotify::Event::Type

def prepare(file)
  `touch #{file}`
end

def cleanup(file)
  `rm #{file}`
end
