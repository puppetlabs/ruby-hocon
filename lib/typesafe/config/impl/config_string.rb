require 'typesafe/config/impl'
require 'typesafe/config/impl/abstract_config_value'
require 'typesafe/config/config_value_type'
require 'typesafe/config/impl/config_impl_util'

class Typesafe::Config::Impl::ConfigString < Typesafe::Config::Impl::AbstractConfigValue
  ConfigImplUtil = Typesafe::Config::Impl::ConfigImplUtil

  def initialize(origin, value)
    super(origin)
    @value = value
  end

  def value_type
    Typesafe::Config::ConfigValueType::STRING
  end

  def unwrapped
    @value
  end

  def transform_to_string
    @value
  end

  def render_value_to_sb(sb, indent_size, at_root, options)
    if options.json?
      sb << ConfigImplUtil.render_json_string(@value)
    else
      sb << ConfigImplUtil.render_string_unquoted_if_possible(@value)
    end
  end

  def new_copy(origin)
    Typesafe::Config::Impl::ConfigString.new(origin, @value)
  end
end