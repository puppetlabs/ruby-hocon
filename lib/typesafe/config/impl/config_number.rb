require 'typesafe/config/impl'
require 'typesafe/config/impl/abstract_config_value'

class Typesafe::Config::Impl::ConfigNumber < Typesafe::Config::Impl::AbstractConfigValue
  ## sigh... requiring these subclasses before this class
  ## is declared would cause an error.  Thanks, ruby.
  require 'typesafe/config/impl/config_int'
  require 'typesafe/config/impl/config_float'

  def self.new_number(origin, number, original_text)
    as_int = number.to_i
    if as_int == number
      Typesafe::Config::Impl::ConfigInt.new(origin, as_int, original_text)
    else
      Typesafe::Config::Impl::ConfigFloat.new(origin, number, original_text)
    end
  end

  def initialize(origin, original_text)
    super(origin)
    @original_text = original_text
  end

  def transform_to_string
    @original_text
  end
end