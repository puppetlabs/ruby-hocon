require 'typesafe/config'
require 'typesafe/config/config_parse_options'
require 'typesafe/config/impl/parseable'

class Typesafe::Config::ConfigFactory
  def self.parse_file(file_path, options = Typesafe::Config::ConfigParseOptions.defaults)
    Typesafe::Config::Impl::Parseable.new_file(file_path, options).parse.to_config
  end
end