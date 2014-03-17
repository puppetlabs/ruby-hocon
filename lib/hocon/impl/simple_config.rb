require 'hocon/impl'

class Hocon::Impl::SimpleConfig
  def initialize(object)
    @object = object
  end

  def root
    @object
  end
end