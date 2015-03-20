# encoding: utf-8

require 'hocon/impl'

class Hocon::Impl::SimpleIncludeContext
  def initialize(parseable)
    @parseable = parseable
  end
end