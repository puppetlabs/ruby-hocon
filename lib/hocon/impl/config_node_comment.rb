# encoding: utf-8

require_relative '../../hocon/impl'
require_relative '../../hocon/config_error'
require_relative '../../hocon/impl/config_node_single_token'
require_relative '../../hocon/impl/tokens'

class Hocon::Impl::ConfigNodeComment < Hocon::Impl::ConfigNodeSingleToken
  def initialize(comment)
    super(comment)
    unless Hocon::Impl::Tokens.comment?(@token)
      raise Hocon::ConfigError::ConfigBugOrBrokenError, 'Tried to create a ConfigNodeComment from a non-comment token'
    end
  end

  def comment_text
    Hocon::Impl::Tokens.comment_text(@token)
  end
end