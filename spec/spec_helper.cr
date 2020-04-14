require "spec"
require "../src/inotify"

TIME       = 500.milliseconds
TEST_DIR   = "./spec/test"
TEST_FILE  = "#{TEST_DIR}/file.txt"
EVENT_CHAN = Channel(Inotify::Event).new

alias Type = Inotify::Event::Type

def prepare(file)
  File.open(file, "a").close
end

def cleanup(file)
  File.delete(file)
end

def append(file, data)
  File.write(file, data, mode: "a")
end

def no_event?(ch)
  select
  when ch.receive
    false
  else
    true
  end
end
