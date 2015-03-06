require 'hocon/impl'
require 'hocon/impl/token_type'

class Hocon::Impl::Token
  attr_reader :token_type
  def self.new_without_origin(token_type, debug_string)
    Hocon::Impl::Token.new(token_type, nil, debug_string)
  end

  def initialize(token_type, origin, debug_string = nil)
    @token_type = token_type
    @origin = origin
    @debug_string = debug_string
  end

  attr_reader :origin

  def line_number
    if @origin
      @origin.line_number
    else
      -1
    end
  end

  def to_s
    if !@debug_string.nil?
      @debug_string
    else
      Hocon::Impl::TokenType.name(@token_type)
    end
  end

  def ==(other)
    # @origin deliberately left out
    other.is_a?(Hocon::Impl::Token) && @token_type == other.token_type
  end

  def hash
    @token_type.hash
  end
end
