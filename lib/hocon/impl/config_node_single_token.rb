# encoding: utf-8

require_relative '../../hocon/impl'
require_relative '../../hocon/impl/abstract_config_node'

class Hocon::Impl::ConfigNodeSingleToken
  include Hocon::Impl::AbstractConfigNode
  def initialize(t)
    @token = t
  end

  attr_reader :token

  def tokens
    [@token]
  end
end