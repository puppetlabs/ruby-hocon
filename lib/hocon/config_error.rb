require 'hocon'

class Hocon::ConfigError < StandardError
  def initialize(origin, message, cause)
    super(message)
    @origin = origin
    @cause = cause
  end

  class ConfigMissingError < Hocon::ConfigError
  end

  class ConfigNullError < Hocon::ConfigError::ConfigMissingError
    def self.make_message(path, expected)
      if not expected.nil?
        "Configuration key '#{path}' is set to nil but expected #{expected}"
      else
        "Configuration key '#{path}' is nil"
      end
    end
  end

  class ConfigParseError < Hocon::ConfigError
  end

  class ConfigWrongTypeError < Hocon::ConfigError
  end

  class ConfigBugOrBrokenError < Hocon::ConfigError
    def initialize(message, cause)
      super(nil, message, cause)
    end
  end

  class ConfigNotResolvedError < Hocon::ConfigError::ConfigBugOrBrokenError
  end
end
