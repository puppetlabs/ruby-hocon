# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/abstract_config_node'

class Hocon::Impl::ConfigNodeSingleToken < Hocon::Impl::AbstractConfigNode
  def initialize(t)
    @token = t
  end

  attr_reader :token

  def tokens
    [@token]
  end
end