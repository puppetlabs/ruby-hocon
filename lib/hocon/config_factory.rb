# encoding: utf-8

require 'hocon'
require 'hocon/impl/parseable'
require 'hocon/config_parse_options'
require 'hocon/impl/config_impl'
require 'hocon/config_factory'

class Hocon::ConfigFactory
  def self.parse_file(file_path, options = Hocon::ConfigParseOptions.defaults)
    Hocon::Impl::Parseable.new_file(file_path, options).parse.to_config
  end

  def self.parse_string(string, options = Hocon::ConfigParseOptions.defaults)
    Hocon::Impl::Parseable.new_string(string, options).parse.to_config
  end

  def self.parse_file_any_syntax(file_base_name, options)
    Hocon::Impl::ConfigImpl.parse_file_any_syntax(file_base_name, options).to_config
  end

  def self.empty(origin_description = nil)
    Hocon::Impl::ConfigImpl.empty_config(origin_description)
  end

  def self.load_file(file_base_name, options_hash = nil)
    if options_hash.nil?
      options_hash = {}
    end
    parse_options = options_hash[:parse_options] || Hocon::ConfigParseOptions.defaults
    resolve_options = options_hash[:resolve_options] || Hocon::ConfigResolveOptions::defaults

    config = Hocon::ConfigFactory.parse_file_any_syntax(file_base_name, parse_options)

    self.load_from_config(config, resolve_options)
  end

  def self.load_from_config(config, resolve_options)

    config.with_fallback(self.default_reference).resolve(resolve_options)
  end

  def self.default_reference
    Hocon::Impl::ConfigImpl.default_reference
  end
end
