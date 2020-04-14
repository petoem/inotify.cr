require "./spec_helper"

describe Inotify do
  describe ".watcher" do
    it "creates a watcher instance" do
      watcher = Inotify.watcher
      watcher.should be_a Inotify::Watcher
      watcher.close
    end
  end

  describe ".watch" do
    it "one test file" do
      prepare TEST_FILE
      watcher = Inotify.watch TEST_FILE do |event|
        EVENT_CHAN.send event
      end
      append(TEST_FILE, "test")
      EVENT_CHAN.receive.type.should eq Type::MODIFY
      cleanup TEST_FILE
      EVENT_CHAN.receive.type.should eq Type::DELETE_SELF
      EVENT_CHAN.receive.type.should eq Type::IGNORED
      no_event?(EVENT_CHAN).should be_true
      watcher.close
    end
    it "one test directory" do
      watcher = Inotify.watch TEST_DIR do |event|
        EVENT_CHAN.send event
      end
      prepare TEST_FILE
      append(TEST_FILE, "test")
      cleanup TEST_FILE
      EVENT_CHAN.receive.type.should eq Type::CREATE
      EVENT_CHAN.receive.type.should eq Type::MODIFY
      EVENT_CHAN.receive.type.should eq Type::DELETE
      watcher.close
      no_event?(EVENT_CHAN).should be_true
    end
  end

  describe "Watcher" do
    describe "#initialize" do
      it "recursive set to false" do
        watcher = Inotify::Watcher.new false
        watcher.should be_a Inotify::Watcher
        watcher.on_event { |event| EVENT_CHAN.send event }
        watcher.watch TEST_DIR
        Dir.mkdir "#{TEST_DIR}/directory"
        EVENT_CHAN.receive.type.should eq Type::CREATE
        watcher.watching.should_not contain "#{TEST_DIR}/directory"
        watcher.close
        Dir.rmdir "#{TEST_DIR}/directory"
      end
      it "recursive set to true" do
        watcher = Inotify::Watcher.new true
        watcher.should be_a Inotify::Watcher
        watcher.on_event { |event| EVENT_CHAN.send event }
        watcher.watch TEST_DIR
        Dir.mkdir "#{TEST_DIR}/directory"
        EVENT_CHAN.receive.type.should eq Type::CREATE
        watcher.watching.should contain "#{TEST_DIR}/directory"
        watcher.close
        Dir.rmdir "#{TEST_DIR}/directory"
      end
    end

    describe "#on_event" do
      it "add event handler" do
        watcher = Inotify::Watcher.new
        watcher.on_event { |event| EVENT_CHAN.send event }
        watcher.@event_callbacks.size.should eq 1
        watcher.close
      end
      it "allows multiple event handlers" do
        watcher = Inotify::Watcher.new
        watcher.on_event { |event| EVENT_CHAN.send event }
        watcher.on_event { |event| EVENT_CHAN.send event }
        watcher.@event_callbacks.size.should eq 2
        watcher.close
      end
      it "event handler is properly called" do
        watcher = Inotify::Watcher.new
        watcher.on_event { |event| EVENT_CHAN.send event }
        watcher.on_event { |event| EVENT_CHAN.send event }
        prepare TEST_FILE
        watcher.watch TEST_FILE
        append(TEST_FILE, "test")
        # We should get MODIFY two times.
        EVENT_CHAN.receive.should eq EVENT_CHAN.receive
        no_event?(EVENT_CHAN).should be_true
        watcher.close
        cleanup TEST_FILE
      end
    end
    describe "#clear_event_handlers" do
      it "removes all event handlers" do
        watcher = Inotify::Watcher.new
        watcher.on_event { |event| EVENT_CHAN.send event }
        watcher.clear_event_handlers
        watcher.@event_callbacks.should be_empty
        watcher.close
      end
      it "no event handlers are called anymore" do
        watcher = Inotify::Watcher.new
        watcher.on_event { |event| EVENT_CHAN.send event }
        watcher.clear_event_handlers
        watcher.watch TEST_DIR
        prepare TEST_FILE
        cleanup TEST_FILE
        no_event?(EVENT_CHAN).should be_true
        watcher.unwatch TEST_DIR
        watcher.close
      end
    end
    describe "#watch" do
      it "successfully watches directory" do
        watcher = Inotify::Watcher.new
        watcher.watch TEST_DIR
        watcher.watching.should contain TEST_DIR
        watcher.close
      end
      it "successfully watches file" do
        watcher = Inotify::Watcher.new
        prepare TEST_FILE
        watcher.watch TEST_FILE
        watcher.watching.should contain TEST_FILE
        cleanup TEST_FILE
        watcher.close
      end
      it "raises if directory does not exist" do
        watcher = Inotify::Watcher.new
        expect_raises Inotify::Error, "inotify add_watch failed" do
          watcher.watch "./does/not/exist"
        end
        watcher.close
      end
      it "raises if file does not exist" do
        watcher = Inotify::Watcher.new
        expect_raises Inotify::Error, "inotify add_watch failed" do
          watcher.watch "./file/does/not/exist.txt"
        end
        watcher.close
      end
    end

    describe "#unwatch" do
      it "should stop watching file" do
        prepare "#{TEST_DIR}/unwatch.txt"
        watcher = Inotify::Watcher.new
        no_event?(EVENT_CHAN).should be_true
        watcher.on_event { |event| EVENT_CHAN.send event }
        watcher.watch "#{TEST_DIR}/unwatch.txt"
        watcher.watching.should contain "#{TEST_DIR}/unwatch.txt"
        watcher.unwatch "#{TEST_DIR}/unwatch.txt"
        EVENT_CHAN.receive.type.should eq Type::IGNORED
        watcher.watching.should_not contain "#{TEST_DIR}/unwatch.txt"
        cleanup "#{TEST_DIR}/unwatch.txt"
        watcher.close
      end
      it "should stop watching directory" do
        watcher = Inotify::Watcher.new
        no_event?(EVENT_CHAN).should be_true
        watcher.on_event { |event| EVENT_CHAN.send event }
        Dir.mkdir "#{TEST_DIR}/directory"
        watcher.watch "#{TEST_DIR}/directory"
        watcher.watching.should contain "#{TEST_DIR}/directory"
        watcher.unwatch "#{TEST_DIR}/directory"
        EVENT_CHAN.receive.type.should eq Type::IGNORED
        watcher.watching.should_not contain "#{TEST_DIR}/directory"
        Dir.rmdir "#{TEST_DIR}/directory"
        watcher.close
      end
    end

    describe "#watching" do
      it "should return an Array(String)" do
        watcher = Inotify::Watcher.new
        watcher.watching.should be_a Array(String)
        watcher.close
      end
      it "contains watched paths" do
        watcher = Inotify::Watcher.new
        watcher.watch TEST_DIR
        watcher.watching.should contain TEST_DIR
        watcher.close
      end
    end
    describe "#close" do
      it "should properly close fd" do
        watcher = Inotify::Watcher.new
        File.exists?("/proc/#{Process.pid}/fd/#{watcher.@io.fd}").should be_true
        watcher.close
        File.exists?("/proc/#{Process.pid}/fd/#{watcher.@io.fd}").should be_false
      end
    end
  end

  describe "Event" do
    it "#initialize" do
      event = Inotify::Event.new nil, nil, 1, 0, 1
      event.name.should be_nil
      event.path.should be_nil
      event.mask.should eq 1
      event.type.should eq Type::ACCESS
      event.cookie.should eq 0
      event.wd.should eq 1
    end
    describe "#directory?" do
      it "should be false" do
        event = Inotify::Event.new nil, nil, 1, 0, 1
        event.directory?.should be_false
      end
      it "should be true" do
        event = Inotify::Event.new nil, nil, 1073741824, 0, 1
        event.directory?.should be_true
      end
    end
    describe "#type_is?" do
      event = Inotify::Event.new nil, nil, 3, 0, 1
      it "should be MODIFY" do
        event.type_is?(Type::MODIFY.value).should be_true
      end
      it "should not be ATTRIB" do
        event.type_is?(Type::ATTRIB.value).should be_false
      end
    end
    describe Type do
      describe "#parse" do
        it "parse number 0 to UNKNOWN" do
          Inotify::Event::Type.parse(0).should eq Type::UNKNOWN
        end
        it "parse number 8 to CLOSE_WRITE" do
          Inotify::Event::Type.parse(8).should eq Type::CLOSE_WRITE
        end
      end
    end
  end
end
