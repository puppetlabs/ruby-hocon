require 'hocon'

module TestUtils
  Tokens = Hocon::Impl::Tokens
  EOF = Hocon::Impl::TokenType::EOF

  def TestUtils.wrap_tokens(token_list)
    # Wraps token_list in START and EOF tokens
    [Tokens::START] + token_list + [Tokens::EOF]
  end

  def TestUtils.tokenize(input_string)
    origin = Hocon::Impl::SimpleConfigOrigin.new_simple("test")
    options = Hocon::ConfigParseOptions.defaults
    io = StringIO.open(input_string)

    Hocon::Impl::Tokenizer.tokenize(origin, io, options)
  end

  def TestUtils.tokenize_as_list(input_string)
    token_iterator = tokenize(input_string)

    token_list = []

    while true
      token = token_iterator.next
      token_list.push token

      if token.token_type == EOF
        break
      end
    end

    token_list
  end

  def TestUtils.fake_origin
    Hocon::Impl::SimpleConfigOrigin.new_simple("fake origin")
  end

  def TestUtils.token_line(line_number)
    Tokens.new_line(fake_origin.set_line_number(line_number))
  end

  def TestUtils.token_true
    Tokens.new_boolean(fake_origin, true)
  end

  def TestUtils.token_false
    Tokens.new_boolean(fake_origin, false)
  end

  def TestUtils.token_null
    Tokens.new_null(fake_origin)
  end

  def TestUtils.token_unquoted(value)
    Tokens.new_unquoted_text(fake_origin, value)
  end

  def TestUtils.token_comment(value)
    Tokens.new_comment(fake_origin, value)
  end

  def TestUtils.token_string(value)
    Tokens.new_string(fake_origin, value)
  end

  def TestUtils.token_float(value)
    Tokens.new_float(fake_origin, value, nil)
  end

  def TestUtils.token_int(value)
    Tokens.new_int(fake_origin, value, nil)
  end

  def TestUtils.token_maybe_optional_substitution(optional, token_list)
    Tokens.new_substitution(fake_origin(), optional, token_list)
  end

  def TestUtils.token_substitution(*token_list)
    token_maybe_optional_substitution(false, token_list)
  end

  def TestUtils.token_optional_substitution(*token_list)
    token_maybe_optional_substitution(true, token_list)
  end

  def TestUtils.token_key_substitution(value)
    token_substitution(token_string(value))
  end
end
