# encoding: utf-8

require_relative '../../hocon/impl'
require_relative '../../hocon/config_error'
require_relative '../../hocon/impl/abstract_config_node'
require_relative '../../hocon/impl/config_node_simple_value'

class Hocon::Impl::ConfigNodeInclude
  include Hocon::Impl::AbstractConfigNode
  def initialize(children, kind)
    @children = children
    @kind = kind
  end

  attr_reader :kind, :children

  def tokens
    tokens = []
    @children.each do |child|
      tokens += child.tokens
    end
    tokens
  end

  def name
    @children.each do |child|
      if child.is_a?(Hocon::Impl::ConfigNodeSimpleValue)
        return Hocon::Impl::Tokens.value(child.token).unwrapped
      end
    end
    nil
  end
end