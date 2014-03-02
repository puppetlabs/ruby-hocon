require 'typesafe/config/impl'
require 'typesafe/config/impl/config_number'

class Typesafe::Config::Impl::ConfigFloat < Typesafe::Config::Impl::ConfigNumber
  def initialize(origin, value, original_text)
    super(origin, original_text)
    @value = value
  end
end