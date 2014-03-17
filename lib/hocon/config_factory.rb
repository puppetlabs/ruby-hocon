require 'hocon'
require 'hocon/config_parse_options'
require 'hocon/impl/parseable'

class Hocon::ConfigFactory
  def self.parse_file(file_path, options = Hocon::ConfigParseOptions.defaults)
    Hocon::Impl::Parseable.new_file(file_path, options).parse.to_config
  end
end