require "./spec_helper"

describe Inotify do
  it "watch with fiber" do
    Inotify::Watcher.new("./spec/test") do |event|
      pp event
    end

    loop do
      sleep 5
      puts "PING"
    end
  end
end
