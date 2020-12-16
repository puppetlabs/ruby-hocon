# encoding: utf-8

require_relative '../../hocon'
require_relative '../../hocon/impl'

class Hocon::Impl::ResolveMemos

  def initialize(memos = {})
    @memos = memos
  end

  def get(key)
    @memos[key]
  end

  def put(key, value)
    copy = @memos.clone
    copy[key] = value
    Hocon::Impl::ResolveMemos.new(copy)
  end
end
