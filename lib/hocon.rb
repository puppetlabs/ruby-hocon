module Hocon
  require 'hocon/config_factory'
  require 'hocon/config_parse_options'
  require 'hocon/config_error'
  require 'hocon/config_object'
  require 'hocon/config_parse_options'
  require 'hocon/config_render_options'
  require 'hocon/config_syntax'
  require 'hocon/config_value_factory'
  require 'hocon/config_value_type'

  def self.load(file)
    config = Hocon::ConfigFactory.parse_file(file)
    return config.root.unwrapped
  end

  def self.parse(string)
    config = Hocon::ConfigFactory.parse_string(string)
    return config.root.unwrapped
  end
end
