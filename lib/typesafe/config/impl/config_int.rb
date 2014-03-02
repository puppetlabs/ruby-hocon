require 'typesafe/config/impl'
require 'typesafe/config/impl/config_number'
require 'typesafe/config/config_value_type'

class Typesafe::Config::Impl::ConfigInt < Typesafe::Config::Impl::ConfigNumber
  def initialize(origin, value, original_text)
    super(origin, original_text)
    @value = value
  end

  def value_type
    Typesafe::Config::ConfigValueType::NUMBER
  end

  def unwrapped
    @value
  end

  def transform_to_string
    s = super
    if s.nil?
      self.to_s
    else
      s
    end
  end

  def new_copy(origin)
    Typesafe::Config::Impl::ConfigInt.new(origin, @value, @original_text)
  end
end