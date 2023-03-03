# encoding: utf-8

require_relative '../../hocon/config_error'
require_relative '../../hocon/impl'
require_relative '../../hocon/impl/abstract_config_node_value'
require_relative '../../hocon/impl/array_iterator'
require_relative '../../hocon/impl/config_reference'
require_relative '../../hocon/impl/config_string'
require_relative '../../hocon/impl/path_parser'
require_relative '../../hocon/impl/substitution_expression'
require_relative '../../hocon/impl/tokens'

class Hocon::Impl::ConfigNodeSimpleValue
  include Hocon::Impl::AbstractConfigNodeValue

  Tokens = Hocon::Impl::Tokens

  def initialize(value)
    @token = value
  end

  attr_reader :token

  def tokens
    [@token]
  end

  def value
    if Tokens.value?(@token)
      return Tokens.value(@token)
    elsif Tokens.unquoted_text?(@token)
      return Hocon::Impl::ConfigString::Unquoted.new(@token.origin, Tokens.unquoted_text(@token))
    elsif Tokens.substitution?(@token)
      expression = Tokens.get_substitution_path_expression(@token)
      path = Hocon::Impl::PathParser.parse_path_expression(Hocon::Impl::ArrayIterator.new(expression), @token.origin)
      optional = Tokens.get_substitution_optional(@token)

      return Hocon::Impl::ConfigReference.new(@token.origin, Hocon::Impl::SubstitutionExpression.new(path, optional))
    end
    raise Hocon::ConfigError::ConfigBugOrBrokenError, 'ConfigNodeSimpleValue did not contain a valid value token'
  end
end