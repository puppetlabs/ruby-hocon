require 'hocon/impl'
require 'hocon/impl/abstract_config_value'

class Hocon::Impl::ConfigBoolean < Hocon::Impl::AbstractConfigValue
  def initialize(origin, value)
    super(origin)
    @value = value
  end

  def value_type
    Hocon::ConfigValueType::BOOLEAN
  end

  def unwrapped
    @value
  end

  def transform_to_string
    @value.to_s
  end

  def new_copy(origin)
    Hocon::Impl::ConfigBoolean.new(origin, @value)
  end
end
