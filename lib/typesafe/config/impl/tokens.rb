require 'typesafe/config/impl'
require 'typesafe/config/impl/token'
require 'typesafe/config/impl/token_type'
require 'typesafe/config/impl/config_number'
require 'typesafe/config/impl/config_string'

# FIXME the way the subclasses of Token are private with static isFoo and accessors is kind of ridiculous.
class Typesafe::Config::Impl::Tokens
  Token = Typesafe::Config::Impl::Token
  TokenType = Typesafe::Config::Impl::TokenType
  ConfigNumber = Typesafe::Config::Impl::ConfigNumber
  ConfigString = Typesafe::Config::Impl::ConfigString

  START = Token.new_without_origin(TokenType::START, "start of file")
  EOF = Token.new_without_origin(TokenType::EOF, "end of file")
  COMMA = Token.new_without_origin(TokenType::COMMA, "','")
  EQUALS = Token.new_without_origin(TokenType::EQUALS, "'='")
  COLON = Token.new_without_origin(TokenType::COLON, "':'")
  OPEN_CURLY = Token.new_without_origin(TokenType::OPEN_CURLY, "'{'")
  CLOSE_CURLY = Token.new_without_origin(TokenType::CLOSE_CURLY, "'}'")
  OPEN_SQUARE = Token.new_without_origin(TokenType::OPEN_SQUARE, "'['")
  CLOSE_SQUARE = Token.new_without_origin(TokenType::CLOSE_SQUARE, "']'")
  PLUS_EQUALS = Token.new_without_origin(TokenType::PLUS_EQUALS, "'+='")

  class Comment < Token
    def initialize(origin, text)
      super(TokenType::COMMENT, origin)
      @text = text
    end
    attr_reader :text
  end

  # This is not a Value, because it requires special processing
  class Substitution < Token
    def initialize(origin, optional, expression)
      super(TokenType::SUBSTITUTION, origin)
      @optional = optional
      @value = expression
    end
  end

  class UnquotedText < Token
    def initialize(origin, s)
      super(TokenType::UNQUOTED_TEXT, origin)
      @value = s
    end
    attr_reader :value

    def to_s
      "'#{value}'"
    end
  end

  class Value < Token
    def initialize(value)
      super(TokenType::VALUE, value.origin)
      @value = value
    end
    attr_reader :value

    def to_s
      "'#{value.unwrapped}' (#{Typesafe::Config::ConfigValueType.name(value.value_type)})"
    end
  end

  class Line < Token
    def initialize(origin)
      super(TokenType::NEWLINE, origin)
    end
  end

  class Problem < Token
    def initialize(origin, what, message, suggest_quotes, cause)
      super(TokenType::PROBLEM, origin)
      @what = what
      @message = message
      @suggest_quotes = suggest_quotes
      @cause = cause
    end
  end

  def self.new_line(origin)
    Line.new(origin)
  end

  def self.new_comment(origin, text)
    Comment.new(origin, text)
  end

  def self.new_unquoted_text(origin, s)
    UnquotedText.new(origin, s)
  end

  def self.new_value(value)
    Value.new(value)
  end

  def self.new_string(origin, value)
    new_value(ConfigString.new(origin, value))
  end

  def self.new_long(origin, value, original_text)
    new_value(ConfigNumber.new_number(origin, value, original_text))
  end

  def self.comment?(t)
    t.is_a?(Comment)
  end

  def self.comment_text(token)
    if comment?(token)
      token.text
    else
      raise ConfigBugError, "tried to get comment text from #{token}"
    end
  end

  def self.substitution?(t)
    t.is_a?(Substitution)
  end

  def self.unquoted_text?(token)
    token.is_a?(UnquotedText)
  end

  def self.unquoted_text(token)
    if unquoted_text?(token)
      token.value
    else
      raise ConfigBugError, "tried to get unquoted text from #{token}"
    end
  end

  def self.value?(token)
    token.is_a?(Value)
  end

  def self.value(token)
    if token.is_a?(Value)
      token.value
    else
      raise ConfigBugError, "tried to get value of non-value token #{token}"
    end
  end

  def self.value_with_type?(t, value_type)
    value?(t) && (value(t).value_type == value_type)
  end

  def self.newline?(t)
    t.is_a?(Line)
  end

  def self.problem?(t)
    t.is_a?(Problem)
  end
end