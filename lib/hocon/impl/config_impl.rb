require 'hocon/impl'
require 'hocon/impl/simple_includer'

class Hocon::Impl::ConfigImpl
  @default_includer = Hocon::Impl::SimpleIncluder.new

  def self.default_includer
    @default_includer
  end
end