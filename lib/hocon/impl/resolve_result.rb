# encoding: utf-8

require 'hocon'
require 'hocon/impl'

class Hocon::Impl::ResolveResult

  attr_accessor :context, :value

  def initialize(context, value)
    @context = context
    @value = value
  end

  def self.make(context, value)
    self.new(context, value)
  end

  def pop_trace
    self.class.make(@context.pop_trace, value)
  end
end
