# encoding: utf-8

require 'spec_helper'
require 'hocon'
require 'test_utils'

describe Hocon::Parser::ConfigNode do
  Tokens = Hocon::Impl::Tokens

  shared_examples_for "single token node test" do
    it "should render the node with the text of the token" do
      node = TestUtils.config_node_single_token(token)
      expect(node.render).to eq(token.token_text)
    end
  end

  shared_examples_for "key node test" do
    it "should render the node with the text of the path" do
      node = TestUtils.config_node_key(path)
      expect(path).to eq(node.render)
    end
  end

  shared_examples_for "simple value node test" do
    it "should render the original token text" do
      node = TestUtils.config_node_simple_value(token)
      expect(node.render).to eq(token.token_text)
    end
  end

  shared_examples_for "field node test" do
    it "should properly replace the value of a field node" do
      key_val_node = TestUtils.node_key_value_pair(key, value)
      expect(key_val_node.render).to eq("#{key.render} : #{value.render}")
      expect(key_val_node.path.render).to eq(key.render)
      expect(key_val_node.value.render).to eq(value.render)

      new_key_val_node = key_val_node.replace_value(new_value)
      expect(new_key_val_node.render).to eq("#{key.render} : #{new_value.render}")
      expect(new_key_val_node.value.render).to eq(new_value.render)
    end
  end

  shared_examples_for "top level value replace test" do
    it "should replace a value in a ConfigNodeObject" do
      complex_node_children = [TestUtils.node_open_brace,
                               TestUtils.node_key_value_pair(TestUtils.config_node_key(key), value),
                               TestUtils.node_close_brace]
      complex_node = TestUtils.config_node_object(complex_node_children)
      new_node = complex_node.set_value_on_path(key, new_value)
      orig_text = "{#{key} : #{value.render}}"
      final_text = "{#{key} : #{new_value.render}}"

      expect(complex_node.render).to eq(orig_text)
      expect(new_node.render).to eq(final_text)
    end
  end

  shared_examples_for "replace duplicates test" do
    it "should remove duplicates of a key when setting a value" do
      key = TestUtils.config_node_key('foo')
      key_val_pair_1 = TestUtils.node_key_value_pair(key, value1)
      key_val_pair_2 = TestUtils.node_key_value_pair(key, value2)
      key_val_pair_3 = TestUtils.node_key_value_pair(key, value3)
      complex_node = TestUtils.config_node_object([key_val_pair_1, key_val_pair_2, key_val_pair_3])
      orig_text = "#{key_val_pair_1.render}#{key_val_pair_2.render}#{key_val_pair_3.render}"
      final_text = "#{key.render} : 15"

      expect(complex_node.render).to eq(orig_text)
      expect(complex_node.set_value_on_path("foo", TestUtils.node_int(15)).render).to eq(final_text)
    end
  end

  shared_examples_for "non existent path test" do
    it "should properly add a key/value pair if the key does not exist in the object" do
      node = TestUtils.config_node_object([TestUtils.node_key_value_pair(TestUtils.config_node_key("bar"), TestUtils.node_int(15))])
      expect(node.render).to eq('bar : 15')
      new_node = node.set_value_on_path('foo', value)
      final_text = "bar : 15, foo : #{value.render}"
      expect(new_node.render).to eq(final_text)
    end
  end

  ########################
  # ConfigNodeSingleToken
  ########################
  context "create basic config node" do
    # Ensure a ConfigNodeSingleToken can handle all its required token types
    context "start of file" do
      let(:token) { Tokens::START }
      include_examples "single token node test"
    end

    context "end of file" do
      let(:token) { Tokens::EOF }
      include_examples "single token node test"
    end

    context "{" do
      let (:token) { Tokens::OPEN_CURLY }
      include_examples "single token node test"
    end

    context "}" do
      let (:token) { Tokens::CLOSE_CURLY }
      include_examples "single token node test"
    end

    context "[" do
      let (:token) { Tokens::OPEN_SQUARE }
      include_examples "single token node test"
    end

    context "]" do
      let (:token) { Tokens::CLOSE_SQUARE }
      include_examples "single token node test"
    end

    context "," do
      let (:token) { Tokens::COMMA }
      include_examples "single token node test"
    end

    context "=" do
      let (:token) { Tokens::EQUALS }
      include_examples "single token node test"
    end

    context ":" do
      let (:token) { Tokens::COLON }
      include_examples "single token node test"
    end

    context "+=" do
      let (:token) { Tokens::PLUS_EQUALS }
      include_examples "single token node test"
    end

    context "unquoted text" do
      let (:token) { TestUtils.token_unquoted('             ') }
      include_examples "single token node test"
    end

    context "ignored whitespace" do
      let (:token) { TestUtils.token_whitespace('             ') }
      include_examples "single token node test"
    end

    context '\n' do
      let (:token) { TestUtils.token_line(1) }
      include_examples "single token node test"
    end

    context "double slash comment" do
      let (:token) { TestUtils.token_comment_double_slash(" this is a double slash comment  ") }
      include_examples "single token node test"
    end

    context "hash comment" do
      let (:token) { TestUtils.token_comment_hash(" this is a hash comment  ") }
      include_examples "single token node test"
    end
  end

  ####################
  # ConfigNodeSetting
  ####################
  context "create config node setting" do
    # Ensure a ConfigNodeSetting can handle the normal key types
    context "unquoted key" do
      let (:path) { "foo" }
      include_examples "key node test"
    end

    context "quoted_key" do
      let (:path) { "\"Hello I am a key how are you today\"" }
      include_examples "key node test"
    end
  end

  context "path node subpath" do
    it "should produce correct subpaths of path nodes with subpath method" do
      orig_path = 'a.b.c."@$%#@!@#$"."".1234.5678'
      path_node = TestUtils.config_node_key(orig_path)

      expect(path_node.render).to eq(orig_path)
      expect(path_node.sub_path(2).render).to eq('c."@$%#@!@#$"."".1234.5678')
      expect(path_node.sub_path(6).render).to eq('5678')
    end
  end

  ########################
  # ConfigNodeSimpleValue
  ########################
  context "create config node simple value" do
    context "integer" do
      let (:token) { TestUtils.token_int(10) }
      include_examples "simple value node test"
    end

    context "double" do
      let (:token) { TestUtils.token_double(3.14159) }
      include_examples "simple value node test"
    end

    context "false" do
      let (:token) { TestUtils.token_false }
      include_examples "simple value node test"
    end

    context "true" do
      let (:token) { TestUtils.token_true }
      include_examples "simple value node test"
    end

    context "null" do
      let (:token) { TestUtils.token_null }
      include_examples "simple value node test"
    end

    context "quoted text" do
      let (:token) { TestUtils.token_string("Hello my name is string") }
      include_examples "simple value node test"
    end

    context "unquoted text" do
      let (:token) { TestUtils.token_unquoted("mynameisunquotedstring") }
      include_examples "simple value node test"
    end

    context "key substitution" do
      let (:token) { TestUtils.token_key_substitution("c.d") }
      include_examples "simple value node test"
    end

    context "optional substitution" do
      let (:token) { TestUtils.token_optional_substitution(TestUtils.token_unquoted("x.y")) }
      include_examples "simple value node test"
    end

    context "substitution" do
      let (:token) { TestUtils.token_substitution(TestUtils.token_unquoted("a.b")) }
      include_examples "simple value node test"
    end
  end

  ####################
  # ConfigNodeField
  ####################
  context "create ConfigNodeField" do
    let (:key) { TestUtils.config_node_key('"abc"') }
    let (:value) { TestUtils.node_int(123) }

    context "supports quoted keys" do
      let (:new_value) { TestUtils.node_int(245) }
      include_examples "field node test"
    end

    context "supports unquoted keys" do
      let (:key) { TestUtils.config_node_key('abc') }
      let (:new_value) { TestUtils.node_int(245) }
      include_examples "field node test"
    end

    context "can replace a simple value with a different type of simple value" do
      let (:new_value) { TestUtils.node_string('I am a string') }
      include_examples "field node test"
    end

    context "can replace a simple value with a complex value" do
      let (:new_value) { TestUtils.config_node_object([TestUtils.node_open_brace, TestUtils.node_close_brace]) }
      include_examples "field node test"
    end
  end

  ####################
  # Node Replacement
  ####################
  context "replace nodes" do
    let (:key) { "foo" }
    array = TestUtils.config_node_array([TestUtils.node_open_bracket, TestUtils.node_int(10), TestUtils.node_space, TestUtils.node_comma,
                                         TestUtils.node_space, TestUtils.node_int(15), TestUtils.node_close_bracket])
    nested_map = TestUtils.config_node_object([TestUtils.node_open_brace,
                                               TestUtils.node_key_value_pair(TestUtils.config_node_key("abc"),
                                                                             TestUtils.config_node_simple_value(TestUtils.token_string("a string"))),
                                               TestUtils.node_close_brace])

    context "replace an integer with an integer" do
      let (:value) { TestUtils.node_int(10) }
      let (:new_value) { TestUtils.node_int(15) }
      include_examples "top level value replace test"
    end

    context "replace a double with an integer" do
      let (:value) { TestUtils.node_double(3.14159) }
      let (:new_value) { TestUtils.node_int(10000) }
      include_examples "top level value replace test"
    end

    context "replace false with true" do
      let (:value) { TestUtils.node_false }
      let (:new_value) { TestUtils.node_true }
      include_examples "top level value replace test"
    end

    context "replace true with null" do
      let (:value) { TestUtils.node_true }
      let (:new_value) { TestUtils.node_null }
      include_examples "top level value replace test"
    end

    context "replace null with a string" do
      let (:value) { TestUtils.node_null }
      let (:new_value) { TestUtils.node_string("Hello my name is string") }
      include_examples "top level value replace test"
    end

    context "replace a string with unquoted text" do
      let (:value) { TestUtils.node_string("Hello my name is string") }
      let (:new_value) { TestUtils.node_unquoted_text("mynameisunquotedstring") }
      include_examples "top level value replace test"
    end

    context "replace unquoted text with a key substitution" do
      let (:value) { TestUtils.node_unquoted_text("mynameisunquotedstring") }
      let (:new_value) { TestUtils.node_key_substitution("c.d") }
      include_examples "top level value replace test"
    end

    context "replace int with an optional substitution" do
      let (:value) { TestUtils.node_int(10) }
      let (:new_value) { TestUtils.node_optional_substitution(TestUtils.token_unquoted("x.y")) }
      include_examples "top level value replace test"
    end

    context "replace int with a substitution" do
      let (:value) { TestUtils.node_int(10) }
      let (:new_value) { TestUtils.node_substitution(TestUtils.token_unquoted("a.b")) }
      include_examples "top level value replace test"
    end

    context "replace substitution with an int" do
      let (:value) { TestUtils.node_substitution(TestUtils.token_unquoted("a.b")) }
      let (:new_value) { TestUtils.node_int(10) }
      include_examples "top level value replace test"
    end

    context "ensure arrays can be replaced" do
      context "can replace a simple value with an array" do
        let (:value) { TestUtils.node_int(10) }
        let (:new_value) { array }
        include_examples "top level value replace test"
      end

      context "can replace an array with a simple value" do
        let (:value) { array }
        let (:new_value) { TestUtils.node_int(10) }
        include_examples "top level value replace test"
      end

      context "can replace an array with another complex value" do
        let (:value) { array }
        let (:new_value) { TestUtils.config_node_object([TestUtils.node_open_brace, TestUtils.node_close_brace])}
        include_examples "top level value replace test"
      end
    end

    context "ensure objects can be replaced" do
      context "can replace an object with a simple value" do
        let (:value) { nested_map }
        let (:new_value) { TestUtils.node_int(10) }
        include_examples "top level value replace test"
      end

      context "can replace a simple value with an object" do
        let (:value) { TestUtils.node_int(10) }
        let (:new_value) { nested_map }
        include_examples "top level value replace test"
      end

      context "can replace an array with an object" do
        let (:value) { array }
        let (:new_value) { nested_map }
        include_examples "top level value replace test"
      end

      context "can replace an object with an array" do
        let (:value) { nested_map }
        let (:new_value) { array }
        include_examples "top level value replace test"
      end

      context "can replace an object with an empty object" do
        let (:value) { nested_map }
        let (:new_value) { TestUtils.config_node_object([TestUtils.node_open_brace, TestUtils.node_close_brace]) }
        include_examples "top level value replace test"
      end
    end

    context "ensure concatenations can be replaced" do
      concatenation = TestUtils.config_node_concatenation([TestUtils.node_int(10), TestUtils.node_space, TestUtils.node_string("Hello")])

      context "can replace a concatenation with a simple value" do
        let (:value) { concatenation }
        let (:new_value) { TestUtils.node_int(12) }
        include_examples "top level value replace test"
      end

      context "can replace a simple value with a concatenation" do
        let (:value) { TestUtils.node_int(12) }
        let (:new_value) { concatenation }
        include_examples "top level value replace test"
      end

      context "can replace an object with a concatenation" do
        let (:value) { nested_map }
        let (:new_value) { concatenation }
        include_examples "top level value replace test"
      end

      context "can replace a concatenation with an object" do
        let (:value) { concatenation }
        let (:new_value) { nested_map }
        include_examples "top level value replace test"
      end

      context "can replace an array with a concatenation" do
        let (:value) { array }
        let (:new_value) { concatenation }
        include_examples "top level value replace test"
      end

      context "can replace a concatenation with an array" do
        let (:value) { concatenation }
        let (:new_value) { array }
        include_examples "top level value replace test"
      end
    end

    context 'ensure a key with format "a.b" will be properly replaced' do
      let (:key) { 'foo.bar' }
      let (:value) { TestUtils.node_int(10) }
      let (:new_value) { nested_map }
      include_examples "top level value replace test"
    end
  end

  ####################
  # Duplicate Removal
  ####################
  context "remove duplicates" do
    empty_map_node = TestUtils.config_node_object([TestUtils.node_open_brace, TestUtils.node_close_brace])
    empty_array_node = TestUtils.config_node_array([TestUtils.node_open_bracket, TestUtils.node_close_bracket])

    context "duplicates containing simple values will all be removed" do
      let (:value1) { TestUtils.node_int(10) }
      let (:value2) { TestUtils.node_true }
      let (:value3) { TestUtils.node_null }
      include_examples "replace duplicates test"
    end

    context "duplicates containing objects will be removed" do
      let (:value1) { empty_map_node }
      let (:value2) { empty_map_node }
      let (:value3) { empty_map_node }
      include_examples "replace duplicates test"
    end

    context "duplicates containing arrays will be removed" do
      let (:value1) { empty_array_node }
      let (:value2) { empty_array_node }
      let (:value3) { empty_array_node }
      include_examples "replace duplicates test"
    end

    context "duplicates containing a mix of value types will be removed" do
      let (:value1) { TestUtils.node_int(10) }
      let (:value2) { empty_map_node }
      let (:value3) { empty_array_node }
      include_examples "replace duplicates test"
    end
  end

  #################################
  # Addition of non-existent paths
  #################################
  context "add non existent paths" do
    context "adding an integer" do
      let (:value) { TestUtils.node_int(10) }
      include_examples "non existent path test"
    end

    context "adding an array" do
      let (:value) { TestUtils.config_node_array([TestUtils.node_open_bracket, TestUtils.node_int(15), TestUtils.node_close_bracket]) }
      include_examples "non existent path test"
    end

    context "adding an object" do
      let (:value) { TestUtils.config_node_object([TestUtils.node_open_brace,
                                                   TestUtils.node_key_value_pair(TestUtils.config_node_key('foo'),
                                                                                 TestUtils.node_double(3.14)),
                                                   TestUtils.node_close_brace]) }
      include_examples "non existent path test"
    end
  end

  #################################
  # Replacement of nested nodes
  #################################
  context "replace nested nodes" do
    orig_text = "foo : bar\nbaz : {\n\t\"abc.def\" : 123\n\t//This is a comment about the below setting\n\n\tabc : {\n\t\t" +
        "def : \"this is a string\"\n\t\tghi : ${\"a.b\"}\n\t}\n}\nbaz.abc.ghi : 52\nbaz.abc.ghi : 53\n}"
    lowest_level_map = TestUtils.config_node_object([TestUtils.node_open_brace, TestUtils.node_line(6), TestUtils.node_whitespace("\t\t"),
                                                     TestUtils.node_key_value_pair(TestUtils.config_node_key("def"), TestUtils.config_node_simple_value(TestUtils.token_string("this is a string"))),
                                                     TestUtils.node_line(7), TestUtils.node_whitespace("\t\t"),
                                                     TestUtils.node_key_value_pair(TestUtils.config_node_key("ghi"), TestUtils.config_node_simple_value(TestUtils.token_key_substitution("a.b"))),
                                                     TestUtils.node_line(8), TestUtils.node_whitespace("\t"), TestUtils.node_close_brace])
    higher_level_map = TestUtils.config_node_object([TestUtils.node_open_brace, TestUtils.node_line(2), TestUtils.node_whitespace("\t"),
                                                     TestUtils.node_key_value_pair(TestUtils.config_node_key('"abc.def"'), TestUtils.config_node_simple_value(TestUtils.token_int(123))),
                                                     TestUtils.node_line(3), TestUtils.node_whitespace("\t"), TestUtils.node_comment_double_slash("This is a comment about the below setting"),
                                                     TestUtils.node_line(4), TestUtils.node_line(5), TestUtils.node_whitespace("\t"),
                                                     TestUtils.node_key_value_pair(TestUtils.config_node_key("abc"), lowest_level_map), TestUtils.node_line(9), TestUtils.node_close_brace])
    orig_node = TestUtils.config_node_object([TestUtils.node_key_value_pair(TestUtils.config_node_key("foo"), TestUtils.config_node_simple_value(TestUtils.token_unquoted("bar"))),
                                              TestUtils.node_line(1), TestUtils.node_key_value_pair(TestUtils.config_node_key('baz'), higher_level_map), TestUtils.node_line(10),
                                              TestUtils.node_key_value_pair(TestUtils.config_node_key('baz.abc.ghi'), TestUtils.config_node_simple_value(TestUtils.token_int(52))),
                                              TestUtils.node_line(11),
                                              TestUtils.node_key_value_pair(TestUtils.config_node_key('baz.abc.ghi'), TestUtils.config_node_simple_value(TestUtils.token_int(53))),
                                              TestUtils.node_line(12), TestUtils.node_close_brace])
    it "should properly render the original node" do
      expect(orig_node.render).to eq(orig_text)
    end

    it "should properly replae values in the original node" do
      final_text = "foo : bar\nbaz : {\n\t\"abc.def\" : true\n\t//This is a comment about the below setting\n\n\tabc : {\n\t\t" +
          "def : false\n\t\t\n\t\t\"this.does.not.exist@@@+$#\" : {\n\t\t  end : doesnotexist\n\t\t}\n\t}\n}\n\nbaz.abc.ghi : randomunquotedString\n}"

      # Paths with quotes in the name are treated as a single Path, rather than multiple sub-paths
      new_node = orig_node.set_value_on_path('baz."abc.def"', TestUtils.config_node_simple_value(TestUtils.token_true))
      new_node = new_node.set_value_on_path('baz.abc.def', TestUtils.config_node_simple_value(TestUtils.token_false))

      # Repeats are removed from nested maps
      new_node = new_node.set_value_on_path('baz.abc.ghi', TestUtils.config_node_simple_value(TestUtils.token_unquoted('randomunquotedString')))

      # Missing paths are added to the top level if they don't appear anywhere, including in nested maps
      new_node = new_node.set_value_on_path('baz.abc."this.does.not.exist@@@+$#".end', TestUtils.config_node_simple_value(TestUtils.token_unquoted('doesnotexist')))

      # The above operations cause the resultant map to be rendered properly
      expect(new_node.render).to eq(final_text)
    end
  end

end