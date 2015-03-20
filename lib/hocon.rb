# encoding: utf-8

module Hocon
  require 'hocon/config_factory'

  def self.load(file)
    config = Hocon::ConfigFactory.parse_file(file)
    return config.root.unwrapped
  end

  def self.parse(string)
    config = Hocon::ConfigFactory.parse_string(string)
    return config.root.unwrapped
  end
end
