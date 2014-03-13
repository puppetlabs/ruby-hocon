require 'typesafe/config/impl'
require 'typesafe/config/impl/simple_includer'

class Typesafe::Config::Impl::ConfigImpl
  @default_includer = Typesafe::Config::Impl::SimpleIncluder.new

  def self.default_includer
    @default_includer
  end
end