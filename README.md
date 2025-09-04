# inotify

Inotify bindings for [Crystal language](https://github.com/crystal-lang/crystal).

[![GitHub release](https://img.shields.io/github/release/petoem/inotify.cr.svg?style=flat-square)](https://github.com/petoem/inotify.cr/releases)
[![GitHub action](https://github.com/petoem/inotify.cr/actions/workflows/crystal.yml/badge.svg)](https://github.com/petoem/inotify.cr/actions/workflows/crystal.yml)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/petoem/inotify.cr/blob/master/LICENSE)

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  inotify:
    github: petoem/inotify.cr
    version: 1.0.1
```

## Usage

```crystal
require "inotify"

# To watch a file or directory ...
watcher = Inotify.watch "/path/to/file.txt" do |event|
  # your awesome logic
end

# ... for 10 seconds.
sleep 10.seconds
watcher.close
```

_Note: You have to run something in the main fiber or else your program will exit._

More documentation can be found [here](https://petoem.github.io/inotify.cr/).

## Development

To enable logging to `STDOUT` using environment variables, follow the instructions in the [api docs](https://crystal-lang.org/api/0.34.0/Log.html#configure-logging-from-environment-variables). Use log source `inotify` and severity level `DEBUG`.

## Contributing

1. [Fork it!](https://github.com/petoem/inotify.cr/fork)
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [petoem](https://github.com/petoem) Michael Petö - creator, maintainer
