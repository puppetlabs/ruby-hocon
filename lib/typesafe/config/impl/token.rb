require 'typesafe/config/impl'
require 'typesafe/config/impl/token_type'

class Typesafe::Config::Impl::Token
  def self.new_without_origin(token_type, debug_string)
    Typesafe::Config::Impl::Token.new(token_type, nil, debug_string)
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
      Typesafe::Config::Impl::TokenType.name(@token_type)
    end
  end
end