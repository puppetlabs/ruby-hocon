require 'hocon'
require 'spec_helper'

module TestUtils
  Tokens = Hocon::Impl::Tokens
  EOF = Hocon::Impl::TokenType::EOF


  ##################
  # Tokenizer Functions
  ##################
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


  ##################
  # Token Functions
  ##################
  class NotEqualToAnythingElse
    def ==(other)
      other.is_a? NotEqualToAnythingElse
    end

    def hash
      971
    end
  end
end


##################
# RSpec Shared Examples
##################

# Examples for comparing an object that won't equal anything but itself
# Used in the object_equality examples below
shared_examples_for "not_equal_to_other_random_thing" do
  let(:not_equal_to_anything_else) { TestUtils::NotEqualToAnythingElse.new }

  it "should find the first object not equal to a random other thing" do
    expect(first_object).not_to eq(not_equal_to_anything_else)
    expect(not_equal_to_anything_else).not_to eq(first_object)
  end

  it "should find the second object not equal to a random other thing" do
    expect(second_object).not_to eq(not_equal_to_anything_else)
    expect(not_equal_to_anything_else).not_to eq(second_object)
  end
end

# Examples for making sure two objects are equal
shared_examples_for "object_equality" do

  it "should find the first object to be equal to the second object" do
    expect(first_object).to eq(second_object)
  end

  it "should find the second object to be equal to the first object" do
    expect(second_object).to eq(first_object)
  end

  it "should the hash codes of the two objects to be equal" do
    expect(first_object.hash).to eq(second_object.hash)
  end

  include_examples "not_equal_to_other_random_thing"
end

# Examples for making sure two objects are not equal
shared_examples_for "object_inequality" do

  it "should find the first object to not be equal to the second object" do
    expect(first_object).not_to eq(second_object)
  end

  it "should find the second object to not be equal to the first object" do
    expect(second_object).not_to eq(first_object)
  end

  it "should the hash codes of the two objects to not be equal" do
    # hashcode inequality isn't guaranteed, but
    # as long as it happens to work it might
    # detect a bug (if hashcodes are equal,
    # check if it's due to a bug or correct
    # before you remove this)
    expect(first_object.hash).not_to eq(second_object.hash)
  end

  include_examples "not_equal_to_other_random_thing"
end