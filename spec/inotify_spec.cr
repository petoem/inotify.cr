require "./spec_helper"

describe Inotify do
  it "Watch" do
    fd = LibInotify.init
    raise "inotify init failed" if fd < 0

    wd = LibInotify.add_watch(fd, "./spec/test", LibInotify::IN_MODIFY | LibInotify::IN_CREATE | LibInotify::IN_DELETE)
    raise "inotify add_watch failed" if wd == -1

    slice = Slice(UInt8).new(LibInotify::BUF_LEN)
    bytes_read = LibC.read(fd, slice.pointer(slice.size).as(Void*), slice.size)

    pp bytes_read
    pp LibInotify::EVENT_SIZE
    
    event = slice.unsafe_as(LibInotify::Event)
    pp event
    # Try to read filename
    pp String.new(event.name, event.len).valid_encoding?
    # pp String.new(event.name, event.len)
    pp String.new(event.name, event.len).includes?("T.txt")
    # Try to read filename with slice
    slice_name = Slice.new(event.name, event.len)
    # pp String.new(slice)
    pp String.new(slice).includes?("T.txt")

    LibInotify.rm_watch(fd, wd)
    LibC.close(fd)
  end
end
