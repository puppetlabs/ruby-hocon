# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/simple_includer'

class Hocon::Impl::SimpleIncludeContext
  def initialize(parseable)
    @parseable = parseable
  end

  def parse_options
    Hocon::Impl::SimpleIncluder.clear_for_include(@parseable.options)
  end
end
