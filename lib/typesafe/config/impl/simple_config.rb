require 'typesafe/config/impl'

class Typesafe::Config::Impl::SimpleConfig
  def initialize(object)
    @object = object
  end

  def root
    @object
  end
end