lib LibInotify
  # Supported events suitable for MASK parameter of INOTIFY_ADD_WATCH.
  IN_ACCESS        = 0x00000001                                                  # File was accessed.
  IN_MODIFY        = 0x00000002                                                  # File was modified.
  IN_ATTRIB        = 0x00000004                                                  # Metadata changed.
  IN_CLOSE_WRITE   = 0x00000008                                                  # Writtable file was closed.
  IN_CLOSE_NOWRITE = 0x00000010                                                  # Unwrittable file closed.
  IN_CLOSE         = (LibInotify::IN_CLOSE_WRITE | LibInotify::IN_CLOSE_NOWRITE) # Close.
  IN_OPEN          = 0x00000020                                                  # File was opened.
  IN_MOVED_FROM    = 0x00000040                                                  # File was moved from X.
  IN_MOVED_TO      = 0x00000080                                                  # File was moved to Y.
  IN_MOVE          = (LibInotify::IN_MOVED_FROM | LibInotify::IN_MOVED_TO)       # Moves.
  IN_CREATE        = 0x00000100                                                  # Subfile was created.
  IN_DELETE        = 0x00000200                                                  # Subfile was deleted.
  IN_DELETE_SELF   = 0x00000400                                                  # Self was deleted.
  IN_MOVE_SELF     = 0x00000800                                                  # Self was moved.

  # Events sent by the kernel.
  IN_UNMOUNT    = 0x00002000 # Backing fs was unmounted.
  IN_Q_OVERFLOW = 0x00004000 # Event queued overflowed.
  IN_IGNORED    = 0x00008000 # File was ignored.

  # Helper events.
  # IN_CLOSE = (IN_CLOSE_WRITE | IN_CLOSE_NOWRITE) # Close.
  # IN_MOVE = (IN_MOVED_FROM | IN_MOVED_TO) # Moves.

  # Special flags.
  IN_ONLYDIR     = 0x01000000 # Only watch the path if it is a directory.
  IN_DONT_FOLLOW = 0x02000000 # Do not follow a sym link.
  IN_EXCL_UNLINK = 0x04000000 # Exclude events on unlinked objects.
  IN_MASK_ADD    = 0x20000000 # Add to the mask of an already existing watch.
  IN_ISDIR       = 0x40000000 # Event occurred against dir.
  IN_ONESHOT     = 0x80000000 # Only send event once.

  # All events which a program can wait on.
  IN_ALL_EVENTS = (IN_ACCESS | IN_MODIFY | IN_ATTRIB | IN_CLOSE_WRITE | IN_CLOSE_NOWRITE | IN_OPEN | IN_MOVED_FROM | IN_MOVED_TO | IN_CREATE | IN_DELETE | IN_DELETE_SELF | IN_MOVE_SELF)

  EVENT_SIZE = sizeof(Event)
  BUF_LEN    = 1024 * (EVENT_SIZE + 16)

  struct Event
    wd : LibC::Int
    mask : Uint32T
    cookie : Uint32T
    len : Uint32T
    name : LibC::Char*
  end

  alias Uint32T = LibC::UInt
  fun init = inotify_init : LibC::Int
  fun init = inotify_init1(__flags : LibC::Int) : LibC::Int
  fun add_watch = inotify_add_watch(__fd : LibC::Int, __name : LibC::Char*, __mask : Uint32T) : LibC::Int
  fun rm_watch = inotify_rm_watch(__fd : LibC::Int, __wd : LibC::Int) : LibC::Int
end
