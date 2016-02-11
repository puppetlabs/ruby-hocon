# encoding: utf-8

module Hocon
  def self.load(file)
    # doing this require lazily, because otherwise, classes that need to
    # `require 'hocon'` to get the module into scope will end up recursing
    # through this require and probably ending up with circular dependencies.
    require 'hocon/config_factory'
    config = Hocon::ConfigFactory.load_file(file)
    return config.root.unwrapped
  end

  def self.parse(string)
    # doing this require lazily, because otherwise, classes that need to
    # `require 'hocon'` to get the module into scope will end up recursing
    # through this require and probably ending up with circular dependencies.
    require 'hocon/config_factory'
    config = Hocon::ConfigFactory.parse_string(string)
    return config.root.unwrapped
  end
end
