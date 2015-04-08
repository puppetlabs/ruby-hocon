# encoding: utf-8

require 'spec_helper'
require 'hocon'
require 'hocon/impl/config_document_parser'
require 'test_utils'

describe "ConfigDocumentParser" do
  ConfigDocumentParser = Hocon::Impl::ConfigDocumentParser
  ConfigParseOptions = Hocon::ConfigParseOptions
  ConfigSyntax = Hocon::ConfigSyntax
  shared_examples_for "parse test" do
    it "should correctly render the parsed node" do
      node = ConfigDocumentParser.parse(TestUtils.tokenize_from_s(orig_text), TestUtils.fake_origin, ConfigParseOptions.defaults)
      expect(node.render).to eq(orig_text)
    end
  end

  shared_examples_for "parse JSON failures test" do
    it "should thrown an exception when parsing invalid JSON" do
      e = TestUtils.intercept(Hocon::ConfigError) {
        ConfigDocumentParser.parse(TestUtils.tokenize_from_s(orig_text), TestUtils.fake_origin, ConfigParseOptions.defaults.set_syntax(ConfigSyntax::JSON))
      }
      expect(e.message).to include(contains_message)
    end
  end

  shared_examples_for "parse simple value test" do
    it "should correctly parse and render the original text as CONF" do
      expected_rendered_text = final_text.nil? ? orig_text : final_text
      node = ConfigDocumentParser.parse_value(TestUtils.tokenize_from_s(orig_text), TestUtils.fake_origin, ConfigParseOptions.defaults)
      expect(node.render).to eq(expected_rendered_text)
      expect(node).to be_a(Hocon::Impl::ConfigNodeSimpleValue)
    end

    it "should correctly parse and render the original text as JSON" do
      expected_rendered_text = final_text.nil? ? orig_text : final_text
      nodeJSON = ConfigDocumentParser.parse_value(TestUtils.tokenize_from_s(orig_text), TestUtils.fake_origin, ConfigParseOptions.defaults.set_syntax(ConfigSyntax::JSON))
      expect(nodeJSON.render).to eq(expected_rendered_text)
      expect(nodeJSON).to be_a(Hocon::Impl::ConfigNodeSimpleValue)
    end
  end

  shared_examples_for "parse complex value test" do
    it "should correctly parse and render the original text as CONF" do
      node = ConfigDocumentParser.parse_value(TestUtils.tokenize_from_s(orig_text), TestUtils.fake_origin, ConfigParseOptions.defaults)
      expect(node.render).to eq(orig_text)
      expect(node).to be_a(Hocon::Impl::ConfigNodeComplexValue)
    end

    it "should correctly parse and render the original text as JSON" do
      nodeJSON = ConfigDocumentParser.parse_value(TestUtils.tokenize_from_s(orig_text), TestUtils.fake_origin, ConfigParseOptions.defaults.set_syntax(ConfigSyntax::JSON))
      expect(nodeJSON.render).to eq(orig_text)
      expect(nodeJSON).to be_a(Hocon::Impl::ConfigNodeComplexValue)
    end
  end

  shared_examples_for "parse single value invalid JSON test" do
    it "should correctly parse and render the original text as CONF" do
      node = ConfigDocumentParser.parse_value(TestUtils.tokenize_from_s(orig_text), TestUtils.fake_origin, ConfigParseOptions.defaults)
      expect(node.render).to eq(orig_text)
    end

    it "should throw an exception when parsing the original text as JSON" do
      e = TestUtils.intercept(Hocon::ConfigError) {
        ConfigDocumentParser.parse_value(TestUtils.tokenize_from_s(orig_text), TestUtils.fake_origin, ConfigParseOptions.defaults.set_syntax(ConfigSyntax::JSON))
      }
      expect(e.message).to include(contains_message)
    end
  end

  shared_examples_for "parse leading trailing failure" do
    it "should throw an exception when parsing an invalid single value" do
      e = TestUtils.intercept(Hocon::ConfigError) {
        ConfigDocumentParser.parse_value(TestUtils.tokenize_from_s(orig_text), TestUtils.fake_origin, ConfigParseOptions.defaults)
      }
      expect(e.message).to include("The value from setValue cannot have leading or trailing newlines, whitespace, or comments")
    end
  end

  context "parse_success" do
    context "simple map with no braces" do
      let (:orig_text) { "foo:bar" }
      include_examples "parse test"
    end

    context "simple map with no braces and whitespace" do
      let (:orig_text) { " foo : bar " }
      include_examples "parse test"
    end

    context "include with no braces" do
      let (:orig_text) { 'include "foo.conf" ' }
      include_examples "parse test"
    end

    context "simple map with no braces and newlines" do
      let (:orig_text) { "   \nfoo:bar\n    " }
      include_examples "parse test"
    end

    context "map with no braces and all simple types" do
      let (:orig_text) { '
        aUnquoted : bar
        aString = "qux"
        aNum:123
        aDouble=123.456
        aTrue=true
        aFalse=false
        aNull=null
        aSub =  ${a.b}
        include "foo.conf"
        ' }
      include_examples "parse test"
    end

    context "empty map" do
      let (:orig_text) { "{}" }
      include_examples "parse test"
    end

    context "simple map with braces" do
      let (:orig_text) { "{foo:bar}" }
      include_examples "parse test"
    end

    context "simple map with braces and whitespace" do
      let (:orig_text) { "{  foo  :  bar  }" }
      include_examples "parse test"
    end

    context "simple map with braces and trailing whitespace" do
      let (:orig_text) { "{foo:bar}     " }
      include_examples "parse test"
    end

    context "simple map with braces and include" do
      let (:orig_text) { '{include "foo.conf"}' }
      include_examples "parse test"
    end

    context "simple map with braces and leading/trailing newlines" do
      let (:orig_text) { "\n{foo:bar}\n" }
      include_examples "parse test"
    end

    context "map with braces and all simple types" do
      let (:orig_text) { '{
          aUnquoted : bar
          aString = "qux"
          aNum:123
          aDouble=123.456
          aTrue=true
          aFalse=false
          aNull=null
          aSub =  ${a.b}
          include "foo.conf"
          }' }
      include_examples "parse test"
    end

    context "maps can be nested within other maps" do
      let(:orig_text) {
        '
          foo.bar.baz : {
            qux : "abcdefg"
            "abc".def."ghi" : 123
            abc = { foo:bar }
          }
          qux = 123.456
          '}
      include_examples "parse test"
    end

    context "comments can be parsed in maps" do
      let(:orig_text) {
        '{
          foo: bar
          // This is a comment
          baz:qux // This is another comment
         }'}
      include_examples "parse test"
    end

    context "empty array" do
      let (:orig_text) { "[]" }
      include_examples "parse test"
    end

    context "single-element array" do
      let (:orig_text) { "[foo]" }
      include_examples "parse test"
    end

    context "trailing comment" do
      let (:orig_text) { "[foo,]" }
      include_examples "parse test"
    end

    context "trailing comment and whitespace" do
      let (:orig_text) { "[foo,]     " }
      include_examples "parse test"
    end

    context "leading and trailing whitespace" do
      let (:orig_text) { "   \n[]\n   " }
      include_examples "parse test"
    end

    context "array with all simple types" do
      let (:orig_text) { '[foo, bar,"qux", 123,123.456, true,false, null, ${a.b}]' }
      include_examples "parse test"
    end

    context "array with all simple types and weird whitespace" do
      let (:orig_text) { '[foo,   bar,"qux"    , 123 ,  123.456, true,false, null,   ${a.b}   ]' }
      include_examples "parse test"
    end

    context "basic concatenation inside an array" do
      let (:orig_text) { "[foo bar baz qux]" }
      include_examples "parse test"
    end

    context "basic concatenation inside a map" do
      let (:orig_text) { "{foo: foo bar baz qux}" }
      include_examples "parse test"
    end

    context "complex concatenation in an array with multiple elements" do
      let (:orig_text) { "[abc 123 123.456 null true false [1, 2, 3] {a:b}, 2]" }
      include_examples "parse test"
    end

    context "complex node with all types" do
      let (:orig_text) {
        '{
          foo: bar baz    qux    ernie
          // The above was a concatenation

          baz   =   [ abc 123, {a:12
                                b: {
                                  c: 13
                                  d: {
                                    a: 22
                                    b: "abcdefg" # this is a comment
                                    c: [1, 2, 3]
                                  }
                                }
                                }, # this was an object in an array
                                //The above value is a map containing a map containing a map, all in an array
                                22,
                                // The below value is an array contained in another array
                                [1,2,3]]
          // This is a map with some nested maps and arrays within it, as well as some concatenations
          qux {
            baz: abc 123
            bar: {
              baz: abcdefg
              bar: {
                a: null
                b: true
                c: [true false 123, null, [1, 2, 3]]
              }
            }
          }
        // Did I cover everything?
        }'
      }
      include_examples "parse test"
    end

    context "can correctly parse a JSON string" do
      it "should correctly parse and render a JSON string" do
        orig_text =
            '{
              "foo": "bar",
              "baz": 123,
              "qux": true,
              "array": [
                {"a": true,
                 "c": false},
                12
              ]
           }
        '
        node = ConfigDocumentParser.parse(TestUtils.tokenize_from_s(orig_text), TestUtils.fake_origin, ConfigParseOptions.defaults.set_syntax(ConfigSyntax::JSON))
        expect(node.render).to eq(orig_text)
      end
    end
  end

  context "parse JSON failures" do
    context "JSON does not support concatenations" do
      let (:orig_text) { '{ "foo": 123 456 789 } ' }
      let (:contains_message) { "Expecting close brace } or a comma" }
      include_examples "parse JSON failures test"
    end

    context "JSON must begin with { or [" do
      let (:orig_text) { '"a": 123, "b": 456' }
      let (:contains_message) { "Document must have an object or array at root" }
      include_examples "parse JSON failures test"
    end

    context "JSON does not support unquoted text" do
      let (:orig_text) { '{"foo": unquotedtext}' }
      let (:contains_message) { "Token not allowed in valid JSON" }
      include_examples "parse JSON failures test"
    end

    context "JSON does not support substitutions" do
      let (:orig_text) { '{"foo": ${"a.b"}}' }
      let (:contains_message) { "Substitutions (${} syntax) not allowed in JSON" }
      include_examples "parse JSON failures test"
    end

    context "JSON does not support multi-element paths" do
      let (:orig_text) { '{"foo"."bar": 123}' }
      let (:contains_message) { "Token not allowed in valid JSON" }
      include_examples "parse JSON failures test"
    end

    context "JSON does not support =" do
      let (:orig_text) { '{"foo"=123}' }
      let (:contains_message) { "Key '\"foo\"' may not be followed by token: '='" }
      include_examples "parse JSON failures test"
    end

    context "JSON does not support +=" do
      let (:orig_text) { '{"foo" += "bar"}' }
      let (:contains_message) { "Key '\"foo\"' may not be followed by token: '+='" }
      include_examples "parse JSON failures test"
    end

    context "JSON does not support duplicate keys" do
      let (:orig_text) { '{"foo" : 123, "foo": 456}' }
      let (:contains_message) { "JSON does not allow duplicate fields" }
      include_examples "parse JSON failures test"
    end

    context "JSON does not support trailing commas" do
      let (:orig_text) { '{"foo" : 123,}' }
      let (:contains_message) { "expecting a field name after a comma, got a close brace } instead" }
      include_examples "parse JSON failures test"
    end

    context "JSON does not support empty documents" do
      let (:orig_text) { '' }
      let (:contains_message) { "Empty document" }
      include_examples "parse JSON failures test"
    end
  end

  context "parse single values" do
    let (:final_text) { nil }

    context "parse a single integer" do
      let (:orig_text) { "123" }
      include_examples "parse simple value test"
    end

    context "parse a single double" do
      let (:orig_text) { "123.456" }
      include_examples "parse simple value test"
    end

    context "parse a single string" do
      let (:orig_text) { '"a string"' }
      include_examples "parse simple value test"
    end

    context "parse true" do
      let (:orig_text) { "true" }
      include_examples "parse simple value test"
    end

    context "parse false" do
      let (:orig_text) { "false" }
      include_examples "parse simple value test"
    end

    context "parse null" do
      let (:orig_text) { "null" }
      include_examples "parse simple value test"
    end

    context "parse a map" do
      let (:orig_text) { '{"a": "b"}' }
      include_examples "parse complex value test"
    end

    context "parse an array" do
      let (:orig_text) { '{"a": "b"}' }
      include_examples "parse complex value test"
    end

    it "should parse concatenations when using CONF syntax" do
      orig_text = "123 456 \"abc\""
      node = ConfigDocumentParser.parse_value(TestUtils.tokenize_from_s(orig_text), TestUtils.fake_origin, ConfigParseOptions.defaults)
      expect(node.render).to eq(orig_text)
    end

    it "should parse keys with no separators and object values with CONF parsing" do
      orig_text = '{"foo" { "bar" : 12 } }'
      node = ConfigDocumentParser.parse_value(TestUtils.tokenize_from_s(orig_text), TestUtils.fake_origin, ConfigParseOptions.defaults)
      expect(node.render).to eq(orig_text)
    end
  end

  context "parse single values failures" do
    context "throws on leading whitespace" do
      let (:orig_text) { "   123" }
      include_examples "parse leading trailing failure"
    end

    context "throws on trailing whitespace" do
      let (:orig_text) { "123   " }
      include_examples "parse leading trailing failure"
    end

    context "throws on leading and trailing whitespace" do
      let (:orig_text) { " 123 " }
      include_examples "parse leading trailing failure"
    end

    context "throws on leading newline" do
      let (:orig_text) { "\n123" }
      include_examples "parse leading trailing failure"
    end

    context "throws on trailing newline" do
      let (:orig_text) { "123\n" }
      include_examples "parse leading trailing failure"
    end

    context "throws on leading and trailing newline" do
      let (:orig_text) { "\n123\n" }
      include_examples "parse leading trailing failure"
    end

    context "throws on leading and trailing comments" do
      let (:orig_text) { "#thisisacomment\n123#comment" }
      include_examples "parse leading trailing failure"
    end

    context "throws on whitespace after a concatenation" do
      let (:orig_text) { "123 456 789   " }
      include_examples "parse leading trailing failure"
    end

    context "throws on unquoted text in JSON" do
      let (:orig_text) { "unquotedtext" }
      let (:contains_message) { "Token not allowed in valid JSON" }
      include_examples("parse single value invalid JSON test")
    end

    context "throws on substitutions in JSON" do
      let (:orig_text) { "${a.b}" }
      let (:contains_message) { "Substitutions (${} syntax) not allowed in JSON" }
      include_examples("parse single value invalid JSON test")
    end

    it "should throw an error when parsing concatenations in JSON" do
      orig_text = "123 456 \"abc\""
      e = TestUtils.intercept(Hocon::ConfigError) {
        ConfigDocumentParser.parse_value(TestUtils.tokenize_from_s(orig_text), TestUtils.fake_origin, ConfigParseOptions.defaults.set_syntax(ConfigSyntax::JSON))
      }
      expect(e.message).to include("Parsing JSON and the value set in setValue was either a concatenation or had trailing whitespace, newlines, or comments")
    end

    it "should throw an error when parsing keys with no separators in JSON" do
      orig_text = '{"foo" { "bar" : 12 } }'
      e = TestUtils.intercept(Hocon::ConfigError) {
        ConfigDocumentParser.parse_value(TestUtils.tokenize_from_s(orig_text), TestUtils.fake_origin, ConfigParseOptions.defaults.set_syntax(ConfigSyntax::JSON))
      }
      expect(e.message).to include("Key '\"foo\"' may not be followed by token: '{'")
    end
  end

  context "parse empty document" do
    it "should parse an empty document with CONF syntax" do
      node = ConfigDocumentParser.parse(TestUtils.tokenize_from_s(""), TestUtils.fake_origin, ConfigParseOptions.defaults)
      expect(node.value).to be_a(Hocon::Impl::ConfigNodeObject)
      expect(node.value.children.empty?).to be_truthy
    end

    it "should parse a document with only comments and whitespace with CONF syntax" do
      node = ConfigDocumentParser.parse(TestUtils.tokenize_from_s("#comment\n#comment\n\n"), TestUtils.fake_origin, ConfigParseOptions.defaults)
      expect(node.value).to be_a(Hocon::Impl::ConfigNodeObject)
    end

  end
end