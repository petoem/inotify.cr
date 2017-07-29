require "logger"

module Inotify
  LOG = Logger.new(STDOUT)
  LOG.level = Logger::Severity.parse(ENV["LOG_LEVEL"]? || "UNKNOWN")
end
