require 'hocon'

class Hocon::ConfigError < StandardError
  def initialize(origin, message, cause)
    super(message)
    @origin = origin
    @cause = cause
  end

  class ConfigParseError < Hocon::ConfigError
  end

  class ConfigWrongTypeError < Hocon::ConfigError
  end
end
