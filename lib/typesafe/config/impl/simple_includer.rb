require 'typesafe/config/impl'
require 'typesafe/config/impl/full_includer'

class Typesafe::Config::Impl::SimpleIncluder < Typesafe::Config::Impl::FullIncluder
  class Proxy < Typesafe::Config::Impl::FullIncluder
    def initialize(delegate)
      @delegate = delegate
    end
    ## TODO: port remaining implementation when needed
  end

  def self.make_full(includer)
    if includer.is_a?(Typesafe::Config::Impl::FullIncluder)
      includer
    else
      Proxy.new(includer)
    end
  end
end