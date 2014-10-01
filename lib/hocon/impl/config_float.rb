require 'hocon/impl'
require 'hocon/impl/config_number'

class Hocon::Impl::ConfigFloat < Hocon::Impl::ConfigNumber
  def initialize(origin, value, original_text)
    super(origin, original_text)
    @value = value
  end

  def unwrapped
    @value
  end
end