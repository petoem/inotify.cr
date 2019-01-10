require "../src/inotify"

class Debounce
  @waiter : Concurrent::Future(Nil) | Nil

  def initialize(@path : String, @delay : Time::Span, &block : Deque(Inotify::Event) ->)
    @block = block
    @queue = Deque(Inotify::Event).new
    Inotify.watch @path do |event|
      @waiter.try &.cancel
      @queue.push event
      @waiter = delay @delay.seconds do
        @block.call @queue.dup
        @queue.clear
        nil
      end
    end
  end
end

Debounce.new "./spec/test", 5.seconds do |events|
  pp events
end

# To keep program alive
loop do
  sleep 1
  puts "sleep"
end
