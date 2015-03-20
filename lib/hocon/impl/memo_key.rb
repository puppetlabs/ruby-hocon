# encoding: utf-8

require 'hocon'
require 'hocon/impl'

class Hocon::Impl::MemoKey
  def initialize(value, restrict_to_child_or_nil)
    @value = value
    @restrict_to_child_or_nil = restrict_to_child_or_nil
  end
end
