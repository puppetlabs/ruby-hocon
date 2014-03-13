require 'typesafe/config'

class Typesafe::Config::ConfigError < StandardError
  def initialize(origin, message, cause)
    super(message)
    @origin = origin
    @cause = cause
  end

  class ConfigParseError < Typesafe::Config::ConfigError
  end
end