# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/config_number'

class Hocon::Impl::ConfigFloat < Hocon::Impl::ConfigNumber
  def initialize(origin, value, original_text)
    super(origin, original_text)
    @value = value
  end

  attr_reader :value

  def value_type
    Hocon::ConfigValueType::NUMBER
  end

  def unwrapped
    @value
  end
end