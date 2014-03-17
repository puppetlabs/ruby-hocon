require 'hocon/impl'
require 'hocon/impl/full_includer'

class Hocon::Impl::SimpleIncluder < Hocon::Impl::FullIncluder
  class Proxy < Hocon::Impl::FullIncluder
    def initialize(delegate)
      @delegate = delegate
    end
    ## TODO: port remaining implementation when needed
  end

  def self.make_full(includer)
    if includer.is_a?(Hocon::Impl::FullIncluder)
      includer
    else
      Proxy.new(includer)
    end
  end
end