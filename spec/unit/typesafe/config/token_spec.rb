require 'spec_helper'
require 'hocon'
require 'test_utils'
require 'pp'


describe Hocon::Impl::Token do
  Tokens = Hocon::Impl::Tokens

  shared_examples_for "token_equality" do
    let(:not_equal_to_anything_else) { TestUtils::NotEqualToAnythingElse.new }

    it "should find the first token to be equal to the second token" do
      expect(first_token).to eq(second_token)
    end

    it "should find the second token to be equal to the first token" do
      expect(second_token).to eq(first_token)
    end

    it "should the hash codes of the two tokens to be equal" do
      expect(first_token.hash).to eq(second_token.hash)
    end

    it "should find the first token not equal to a random other thing" do
      expect(first_token).not_to eq(not_equal_to_anything_else)
      expect(not_equal_to_anything_else).not_to eq(first_token)
    end

    it "should find the second token not equal to a random other thing" do
      expect(second_token).not_to eq(not_equal_to_anything_else)
      expect(not_equal_to_anything_else).not_to eq(second_token)
    end
  end

  shared_examples_for "token_inequality" do
    let(:not_equal_to_anything_else) { TestUtils::NotEqualToAnythingElse.new }

    it "should find the first token to not be equal to the second token" do
      expect(first_token).not_to eq(second_token)
    end

    it "should find the second token to not be equal to the first token" do
      expect(second_token).not_to eq(first_token)
    end

    it "should the hash codes of the two tokens to not be equal" do
      # hashcode inequality isn't guaranteed, but
      # as long as it happens to work it might
      # detect a bug (if hashcodes are equal,
      # check if it's due to a bug or correct
      # before you remove this)
      expect(first_token.hash).not_to eq(second_token.hash)
    end

    it "should find the first token not equal to a random other thing" do
      expect(first_token).not_to eq(not_equal_to_anything_else)
      expect(not_equal_to_anything_else).not_to eq(first_token)
    end

    it "should find the second token not equal to a random other thing" do
      expect(second_token).not_to eq(not_equal_to_anything_else)
      expect(not_equal_to_anything_else).not_to eq(second_token)
    end
  end

  ####################
  # Equality
  ####################
  context "check token equality" do
    context "syntax tokens" do
      let(:first_token) { Tokens::START }
      let(:second_token) { Tokens::START }

      include_examples "token_equality"
    end

    context "integer tokens" do
      let(:first_token) { TestUtils.token_int(42) }
      let(:second_token) { TestUtils.token_int(42) }

      include_examples "token_equality"
    end

    context "truth tokens" do
      let(:first_token) { TestUtils.token_true }
      let(:second_token) { TestUtils.token_true }

      include_examples "token_equality"
    end

    context "int and float of the same value" do
      let(:first_token) { TestUtils.token_int(10) }
      let(:second_token) { TestUtils.token_float(10.0) }

      include_examples "token_equality"
    end

    context "float tokens" do
      let(:first_token) { TestUtils.token_int(3.14) }
      let(:second_token) { TestUtils.token_int(3.14) }

      include_examples "token_equality"
    end

    context "quoted string tokens" do
      let(:first_token) { TestUtils.token_string("foo") }
      let(:second_token) { TestUtils.token_string("foo") }

      include_examples "token_equality"
    end

    context "unquoted string tokens" do
      let(:first_token) { TestUtils.token_unquoted("foo") }
      let(:second_token) { TestUtils.token_unquoted("foo") }

      include_examples "token_equality"
    end

    context "key substitution tokens" do
      let(:first_token) { TestUtils.token_key_substitution("foo") }
      let(:second_token) { TestUtils.token_key_substitution("foo") }

      include_examples "token_equality"
    end

    context "null tokens" do
      let(:first_token) { TestUtils.token_null }
      let(:second_token) { TestUtils.token_null }

      include_examples "token_equality"
    end

    context "newline tokens" do
      let(:first_token) { TestUtils.token_line(10) }
      let(:second_token) { TestUtils.token_line(10) }

      include_examples "token_equality"
    end
  end


  ####################
  # Inequality
  ####################
  context "check token inequality" do
    context "syntax tokens" do
      let(:first_token) { Tokens::START }
      let(:second_token) { Tokens::OPEN_CURLY }

      include_examples "token_inequality"
    end

    context "integer tokens" do
      let(:first_token) { TestUtils.token_int(42) }
      let(:second_token) { TestUtils.token_int(43) }

      include_examples "token_inequality"
    end

    context "float tokens" do
      let(:first_token) { TestUtils.token_int(3.14) }
      let(:second_token) { TestUtils.token_int(4.14) }

      include_examples "token_inequality"
    end

    context "truth tokens" do
      let(:first_token) { TestUtils.token_true }
      let(:second_token) { TestUtils.token_false }

      include_examples "token_inequality"
    end

    context "quoted string tokens" do
      let(:first_token) { TestUtils.token_string("foo") }
      let(:second_token) { TestUtils.token_string("bar") }

      include_examples "token_inequality"
    end

    context "unquoted string tokens" do
      let(:first_token) { TestUtils.token_unquoted("foo") }
      let(:second_token) { TestUtils.token_unquoted("bar") }

      include_examples "token_inequality"
    end

    context "key substitution tokens" do
      let(:first_token) { TestUtils.token_key_substitution("foo") }
      let(:second_token) { TestUtils.token_key_substitution("bar") }

      include_examples "token_inequality"
    end

    context "newline tokens" do
      let(:first_token) { TestUtils.token_line(10) }
      let(:second_token) { TestUtils.token_line(11) }

      include_examples "token_inequality"
    end

    context "true and int tokens" do
      let(:first_token) { TestUtils.token_true }
      let(:second_token) { TestUtils.token_int(1) }

      include_examples "token_inequality"
    end

    context "string 'true' and true tokens" do
      let(:first_token) { TestUtils.token_true }
      let(:second_token) { TestUtils.token_string("true") }

      include_examples "token_inequality"
    end

    context "int and float of slightly different values" do
      let(:first_token) { TestUtils.token_int(10) }
      let(:second_token) { TestUtils.token_float(10.000001) }

      include_examples "token_inequality"
    end
  end

  context "Check that to_s doesn't throw exception" do
    it "shouldn't throw an exception" do
      # just be sure to_s doesn't throw an exception. It's for debugging
      # so its exact output doesn't matter a lot
      TestUtils.token_true.to_s
      TestUtils.token_false.to_s
      TestUtils.token_int(42).to_s
      TestUtils.token_float(3.14).to_s
      TestUtils.token_null.to_s
      TestUtils.token_unquoted("foo").to_s
      TestUtils.token_string("bar").to_s
      TestUtils.token_key_substitution("a").to_s
      TestUtils.token_line(10).to_s
      Tokens::START.to_s
      Tokens::EOF.to_s
      Tokens::COLON.to_s
    end
  end
end