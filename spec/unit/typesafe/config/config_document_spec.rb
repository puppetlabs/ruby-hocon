# encoding: utf-8

require 'spec_helper'
require 'hocon'
require 'hocon/parser/config_document_factory'
require 'hocon/config_value_factory'
require 'test_utils'

describe "ConfigDocument" do
  ConfigDocumentFactory = Hocon::Parser::ConfigDocumentFactory
  ConfigParseOptions = Hocon::ConfigParseOptions
  ConfigSyntax = Hocon::ConfigSyntax
  SimpleConfigDocument = Hocon::Impl::SimpleConfigDocument
  ConfigValueFactory = Hocon::ConfigValueFactory

  shared_examples_for "config document replace JSON test" do
    let (:config_document) { ConfigDocumentFactory.parse_string(orig_text, ConfigParseOptions.defaults.set_syntax(ConfigSyntax::JSON)) }
    it "should correctly render the parsed JSON document" do
      expect(config_document.render).to eq(orig_text)
    end

    it "should perform a successful replacement on the parsed JSON document" do
      new_document = config_document.set_value(replace_path, new_value)
      #expect(new_document).to be_a(SimpleConfigDocument)
      expect(new_document.render).to eq(final_text)
    end
  end

  shared_examples_for "config document replace CONF test" do
    let (:config_document) { ConfigDocumentFactory.parse_string(orig_text) }
    it "should correctly render the parsed CONF document" do
      expect(config_document.render).to eq(orig_text)
    end

    it "should perform a successful replacement on the parsed CONF document" do
      new_document = config_document.set_value(replace_path, new_value)
      #expect(new_document).to be_a(SimpleConfigDocument)
      expect(new_document.render).to eq(final_text)
    end
  end

  context "ConfigDocument replace" do
    let (:orig_text) {
      '{
              "a":123,
              "b": 123.456,
              "c": true,
              "d": false,
              "e": null,
              "f": "a string",
              "g": [1,2,3,4,5],
              "h": {
                "a": 123,
                "b": {
                  "a": 12
                },
                "c": [1, 2, 3, {"a": "b"}, [1,2,3]]
              }
             }'
    }
    context "parsing/replacement with a very simple map" do
      let(:orig_text) { '{"a":1}' }
      let(:final_text) { '{"a":2}' }
      let (:new_value) { "2" }
      let (:replace_path) { "a" }
      include_examples "config document replace CONF test"
      include_examples "config document replace JSON test"
    end

    context "parsing/replacement with a map without surrounding braces" do
      let (:orig_text) { "a: b\nc = d" }
      let (:final_text) { "a: b\nc = 12" }
      let (:new_value) { "12" }
      let (:replace_path) { "c" }
      include_examples "config document replace CONF test"
    end

    context "parsing/replacement with a complicated map" do
      let (:final_text) {
        '{
              "a":123,
              "b": 123.456,
              "c": true,
              "d": false,
              "e": null,
              "f": "a string",
              "g": [1,2,3,4,5],
              "h": {
                "a": 123,
                "b": {
                  "a": "i am now a string"
                },
                "c": [1, 2, 3, {"a": "b"}, [1,2,3]]
              }
             }'
      }
      let (:new_value) { '"i am now a string"' }
      let (:replace_path) { "h.b.a" }
      include_examples "config document replace CONF test"
      include_examples "config document replace JSON test"
    end

    context "replacing values with maps" do
      let (:final_text) {
        '{
              "a":123,
              "b": 123.456,
              "c": true,
              "d": false,
              "e": null,
              "f": "a string",
              "g": [1,2,3,4,5],
              "h": {
                "a": 123,
                "b": {
                  "a": {"a":"b", "c":"d"}
                },
                "c": [1, 2, 3, {"a": "b"}, [1,2,3]]
              }
             }' }
      let (:new_value) { '{"a":"b", "c":"d"}' }
      let (:replace_path) { "h.b.a" }
      include_examples "config document replace CONF test"
      include_examples "config document replace JSON test"
    end

    context "replacing values with arrays" do
      let (:final_text) {
        '{
              "a":123,
              "b": 123.456,
              "c": true,
              "d": false,
              "e": null,
              "f": "a string",
              "g": [1,2,3,4,5],
              "h": {
                "a": 123,
                "b": {
                  "a": [1,2,3,4,5]
                },
                "c": [1, 2, 3, {"a": "b"}, [1,2,3]]
              }
             }' }
      let (:new_value) { "[1,2,3,4,5]" }
      let (:replace_path) { "h.b.a" }
      include_examples "config document replace CONF test"
      include_examples "config document replace JSON test"
    end

    context "replacing values with concatenations" do
      let (:final_text) {
        '{
              "a":123,
              "b": 123.456,
              "c": true,
              "d": false,
              "e": null,
              "f": "a string",
              "g": [1,2,3,4,5],
              "h": {
                "a": 123,
                "b": {
                  "a": this is a concatenation 123 456 {a:b} [1,2,3] {a: this is another 123 concatenation null true}
                },
                "c": [1, 2, 3, {"a": "b"}, [1,2,3]]
              }
             }' }
      let (:new_value) { "this is a concatenation 123 456 {a:b} [1,2,3] {a: this is another 123 concatenation null true}" }
      let (:replace_path) { "h.b.a" }
      include_examples "config document replace CONF test"
    end
  end

  context "config document multi element duplicates removed" do
    it "should remove all duplicates when setting a value" do
      orig_text = "{a: b, a.b.c: d, a: e}"
      config_doc = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_doc.set_value("a", "2").render).to eq("{a: 2}")
    end

    it "should keep a trailing comma if succeeding elements were removed in CONF" do
      orig_text = "{a: b, a: e, a.b.c: d}"
      config_doc = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_doc.set_value("a", "2").render).to eq("{a: 2, }")
    end

    it "should add the setting if only a multi-element duplicate exists" do
      orig_text = "{a.b.c: d}"
      config_doc = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_doc.set_value("a", "2").render).to eq("{ a : 2}")
    end
  end

  context "config document set new value brace root" do
    let (:orig_text) { "{\n\t\"a\":\"b\",\n\t\"c\":\"d\"\n}" }
    let (:new_value) { "\"f\"" }
    let (:replace_path) { "\"e\"" }

    context "set a new value in CONF" do
      let (:final_text) { "{\n\t\"a\":\"b\",\n\t\"c\":\"d\"\n\t\"e\" : \"f\"\n}" }
      include_examples "config document replace CONF test"
    end

    context "set a new value in JSON" do
      let (:final_text) { "{\n\t\"a\":\"b\",\n\t\"c\":\"d\",\n\t\"e\" : \"f\"\n}" }
      include_examples "config document replace JSON test"
    end
  end

  context "config document set new value no braces" do
    let (:orig_text) { "\"a\":\"b\",\n\"c\":\"d\"\n" }
    let (:final_text) { "\"a\":\"b\",\n\"c\":\"d\"\n\"e\" : \"f\"\n" }
    let (:new_value) { "\"f\"" }
    let (:replace_path) { "\"e\"" }

    include_examples "config document replace CONF test"
  end

  context "config document set new value multi level CONF" do
    let (:orig_text) { "a:b\nc:d" }
    let (:final_text) { "a:b\nc:d\ne : {\n  f : {\n    g : 12\n  }\n}" }
    let (:new_value) { "12" }
    let (:replace_path) { "e.f.g" }

    include_examples "config document replace CONF test"
  end

  context "config document set new value multi level JSON" do
    let (:orig_text) { "{\"a\":\"b\",\n\"c\":\"d\"}" }
    let (:final_text) { "{\"a\":\"b\",\n\"c\":\"d\",\n  \"e\" : {\n    \"f\" : {\n      \"g\" : 12\n    }\n  }}" }
    let (:new_value) { "12" }
    let (:replace_path) { "e.f.g" }

    include_examples "config document replace JSON test"
  end

  context "config document set new config value" do
    let (:orig_text) { "{\"a\": \"b\"}" }
    let (:final_text) { "{\"a\": 12}" }
    let (:config_doc_hocon) { ConfigDocumentFactory.parse_string(orig_text) }
    let (:config_doc_json) { ConfigDocumentFactory.parse_string(orig_text, ConfigParseOptions.defaults.set_syntax(ConfigSyntax::JSON)) }
    let (:new_value) { ConfigValueFactory.from_any_ref(12) }

    it "should successfuly render the original text from both documents" do
      expect(config_doc_hocon.render).to eq(orig_text)
      expect(config_doc_json.render).to eq(orig_text)
    end

    it "should succesfully set a new value on both documents" do
      expect(config_doc_hocon.set_config_value("a", new_value).render).to eq(final_text)
      expect(config_doc_json.set_config_value("a", new_value).render).to eq(final_text)
    end
  end

  context "config document has value" do
    let (:orig_text) { "{a: b, a.b.c.d: e, c: {a: {b: c}}}" }
    let (:config_doc) { ConfigDocumentFactory.parse_string(orig_text) }

    it "should return true on paths that exist in the document" do
      expect(config_doc.has_value?("a")).to be_truthy
      expect(config_doc.has_value?("a.b.c")).to be_truthy
      expect(config_doc.has_value?("c.a.b")).to be_truthy
    end

    it "should return false on paths that don't exist in the document" do
      expect(config_doc.has_value?("c.a.b.c")).to be_falsey
      expect(config_doc.has_value?("a.b.c.d.e")).to be_falsey
      expect(config_doc.has_value?("this.does.not.exist")).to be_falsey
    end
  end

  context "config document remove value" do
    let (:orig_text) { "{a: b, a.b.c.d: e, c: {a: {b: c}}}" }
    let (:config_doc) { ConfigDocumentFactory.parse_string(orig_text) }

    it "should remove a top-level setting with a simple value" do
      expect(config_doc.remove_value("a").render).to eq("{c: {a: {b: c}}}")
    end

    it "should remove a top-level setting with a complex value" do
      expect(config_doc.remove_value("c").render).to eq("{a: b, a.b.c.d: e, }")
    end

    it "should do nothing if the setting does not exist" do
      expect(config_doc.remove_value("this.does.not.exist")).to eq(config_doc)
    end
  end

  context "config document remove value JSON" do
    it "should not leave a trailing comma when removing a value in JSON" do
      orig_text = '{"a": "b", "c": "d"}'
      config_doc = ConfigDocumentFactory.parse_string(orig_text, ConfigParseOptions.defaults.set_syntax(ConfigSyntax::JSON))
      expect(config_doc.remove_value("c").render).to eq('{"a": "b" }')
    end
  end

  context "config document remove multiple" do
    it "should remove duplicate nested keys" do
      orig_text = "a { b: 42 }, a.b = 43, a { b: { c: 44 } }"
      config_doc = ConfigDocumentFactory.parse_string(orig_text)
      removed = config_doc.remove_value("a.b")
      expect(removed.render).to eq("a { }, a { }")
    end
  end

  context "config document remove overridden" do
    it "should remove all instances of keys even if overridden by a top-level key/value pair" do
      orig_text = "a { b: 42 }, a.b = 43, a { b: { c: 44 } }, a : 57 "
      config_doc = ConfigDocumentFactory.parse_string(orig_text)
      removed = config_doc.remove_value("a.b")
      expect(removed.render).to eq("a { }, a { }, a : 57 ")
    end
  end

  context "config document remove nested" do
    it "should remove nested keys if specified" do
      orig_text = "a { b: 42 }, a.b = 43, a { b: { c: 44 } }"
      config_doc = ConfigDocumentFactory.parse_string(orig_text)
      removed = config_doc.remove_value("a.b.c")
      expect(removed.render).to eq("a { b: 42 }, a.b = 43, a { b: { } }")
    end
  end

  context "config document array failures" do
    let (:orig_text) { "[1, 2, 3, 4, 5]" }
    let (:document) { ConfigDocumentFactory.parse_string(orig_text) }

    it "should throw when set_value is called and there is an array at the root" do
      e = TestUtils.intercept(Hocon::ConfigError) { document.set_value("a", "1") }
      expect(e.message).to include("ConfigDocument had an array at the root level")
    end

    it "should throw when has_value is called and there is an array at the root" do
      e = TestUtils.intercept(Hocon::ConfigError) { document.has_value?("a") }
      expect(e.message).to include("ConfigDocument had an array at the root level")
    end

    it "should throw when remove_value is called and there is an array at the root" do
      e = TestUtils.intercept(Hocon::ConfigError) { document.remove_value("a") }
      expect(e.message).to include("ConfigDocument had an array at the root level")
    end
  end

  context "config document JSON replace failure" do
    it "should fail when trying to replace with a value using HOCON syntax in JSON" do
      orig_text = "{\"foo\": \"bar\", \"baz\": \"qux\"}"
      document = ConfigDocumentFactory.parse_string(orig_text, ConfigParseOptions.defaults.set_syntax(ConfigSyntax::JSON))

      e = TestUtils.intercept(Hocon::ConfigError) { document.set_value("foo", "unquoted") }
      expect(e.message).to include("Token not allowed in valid JSON")
    end
  end

  context "config document JSON replace with concatenation failure" do
    it "should fail when trying to add a concatenation into a JSON document" do
      orig_text = "{\"foo\": \"bar\", \"baz\": \"qux\"}"
      document = ConfigDocumentFactory.parse_string(orig_text, ConfigParseOptions.defaults.set_syntax(ConfigSyntax::JSON))

      e = TestUtils.intercept(Hocon::ConfigError) { document.set_value("foo", "1 2 3 concatenation") }
      expect(e.message).to include("Parsing JSON and the value set in setValue was either a concatenation or had trailing whitespace, newlines, or comments")
    end
  end

  context "config document file parse" do
    let (:config_document) { ConfigDocumentFactory.parse_file(TestUtils.resource_file("test01.conf")) }
    let (:file_text) {
      file = File.open(TestUtils.resource_file("test01.conf"), "rb")
      contents = file.read
      file.close
      contents
    }

    it "should correctly parse from a file" do
      expect(config_document.render).to eq(file_text)
    end
  end

  # skipping reader parsing, since we don't support that in ruby hocon

  context "config document indentation single line object" do
    it "should properly indent a value in a single-line map" do
      orig_text = "a { b: c }"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("a.d", "e").render).to eq("a { b: c, d : e }")
    end

    it "should properly indent a value in the top-level when it is on a single line" do
      orig_text = "a { b: c }, d: e"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("f", "g").render).to eq("a { b: c }, d: e, f : g")
    end

    it "should not preserve trailing commas" do
      orig_text = "a { b: c }, d: e,"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("f", "g").render).to eq("a { b: c }, d: e, f : g")
    end

    it "should add necessary keys along the path to the value and properly space them" do
      orig_text = "a { b: c }, d: e,"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("f.g.h", "i").render).to eq("a { b: c }, d: e, f : { g : { h : i } }")
    end

    it "should properly indent keys added to the top-level with curly braces" do
      orig_text = "{a { b: c }, d: e}"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("f", "g").render).to eq("{a { b: c }, d: e, f : g}")
    end

    it "should add necessary keys along the path to the value and properly space them when the root has braces" do
      orig_text = "{a { b: c }, d: e}"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("f.g.h", "i").render).to eq("{a { b: c }, d: e, f : { g : { h : i } }}")
    end
  end

  context "config document indentation multi line object" do
    context "document with no trailing newlines" do
      let (:orig_text) { "a {\n  b: c\n}" }
      let (:config_document) { ConfigDocumentFactory.parse_string(orig_text) }

      it "should properly indent a value in a multi-line map" do
        expect(config_document.set_value("a.e", "f").render).to eq("a {\n  b: c\n  e : f\n}")
      end

      it "should properly add/indent any necessary objects along the way to the value" do
        expect(config_document.set_value("a.d.e.f", "g").render).to eq("a {\n  b: c\n  d : {\n    e : {\n      f : g\n    }\n  }\n}")
      end
    end

    context "document with multi-line root" do
      let (:orig_text) { "a {\n b: c\n}\n" }
      let (:config_document) { ConfigDocumentFactory.parse_string(orig_text) }

      it "should properly indent a value at the root with multiple lines" do
        expect(config_document.set_value("d", "e").render).to eq("a {\n b: c\n}\nd : e\n")
      end

      it "should properly add/indent any necessary objects along the way to the value" do
        expect(config_document.set_value("d.e.f", "g").render).to eq("a {\n b: c\n}\nd : {\n  e : {\n    f : g\n  }\n}\n")
      end
    end
  end

  context "config document indentation nested" do
    it "should properly space a new key/value pair in a nested map in a single-line document" do
      orig_text = "a { b { c { d: e } } }"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("a.b.c.f", "g").render).to eq("a { b { c { d: e, f : g } } }")
    end

    it "should properly space a new key/value pair in a nested map in a multi-line document" do
      orig_text = "a {\n  b {\n    c {\n      d: e\n    }\n  }\n}"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("a.b.c.f", "g").render).to eq("a {\n  b {\n    c {\n      d: e\n      f : g\n    }\n  }\n}")
    end
  end

  context "config document indentation empty object" do
    it "should properly space a new key/value pair in a single-line empty object" do
      orig_text = "a { }"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("a.b", "c").render).to eq("a { b : c }")
    end

    it "should properly indent a new key/value pair in a multi-line empty object" do
      orig_text = "a {\n  b {\n  }\n}"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("a.b.c", "d").render).to eq("a {\n  b {\n    c : d\n  }\n}")
    end
  end

  context "config document indentation multi line value" do
    let (:orig_text) { "a {\n  b {\n    c {\n      d: e\n    }\n  }\n}" }
    let (:config_document) { ConfigDocumentFactory.parse_string(orig_text) }

    it "should successfully insert and indent a multi-line object" do
      expect(config_document.set_value("a.b.c.f", "{\n  g: h\n  i: j\n  k: {\n    l: m\n  }\n}").render
            ).to eq("a {\n  b {\n    c {\n      d: e\n      f : {\n        g: h\n        i: j\n        k: {\n          l: m\n        }\n      }\n    }\n  }\n}")
    end

    it "should successfully insert a concatenation with a multi-line array" do
      expect(config_document.set_value("a.b.c.f", "12 13 [1,\n2,\n3,\n{\n  a:b\n}]").render
            ).to eq("a {\n  b {\n    c {\n      d: e\n      f : 12 13 [1,\n      2,\n      3,\n      {\n        a:b\n      }]\n    }\n  }\n}")
    end
  end

  context "config document indentation multi line value single line object" do
    it "should get weird indentation when adding a multi-line value to a single-line object" do
      orig_text = "a { b { } }"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("a.b.c", "{\n  c:d\n}").render).to eq("a { b { c : {\n   c:d\n } } }")
    end
  end

  context "config document indentation single line object containing multi line value" do
    it "should treat an object with no new-lines outside of its values as a single-line object" do
      orig_text = "a { b {\n  c: d\n} }"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("a.e", "f").render).to eq("a { b {\n  c: d\n}, e : f }")
    end
  end

  context "config document indentation replacing with multi line value" do
    it "should properly indent a multi-line value when replacing a single-line value" do
      orig_text = "a {\n  b {\n    c : 22\n  }\n}"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("a.b.c", "{\n  d:e\n}").render).to eq("a {\n  b {\n    c : {\n      d:e\n    }\n  }\n}")
    end

    it "should properly indent a multi-line value when replacing a single-line value in an object with multiple keys" do
      orig_text = "a {\n  b {\n                f : 10\n    c : 22\n  }\n}"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("a.b.c", "{\n  d:e\n}").render).to eq("a {\n  b {\n                f : 10\n    c : {\n      d:e\n    }\n  }\n}")
    end
  end

  context "config document indentation value with include" do
    it "should indent an include node" do
      orig_text = "a {\n  b {\n    c : 22\n  }\n}"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("a.b.d", "{\n  include \"foo\"\n  e:f\n}").render
            ).to eq("a {\n  b {\n    c : 22\n    d : {\n      include \"foo\"\n      e:f\n    }\n  }\n}")
    end
  end

  context "config document indentation based on include node" do
    it "should indent properly when only an include node is present in the object in which the value is inserted" do
      orig_text = "a : b\n      include \"foo\"\n"
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("c", "d").render).to eq("a : b\n      include \"foo\"\n      c : d\n")
    end
  end

  context "insertion into an empty document" do
    it "should successfully insert a value into an empty document" do
      orig_text = ""
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("a", "1").render).to eq("a : 1")
    end

    it "should successfully insert a multi-line object into an empty document" do
      orig_text = ""
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      expect(config_document.set_value("a.b", "1").render).to eq("a : {\n  b : 1\n}")
    end

    it "should successfully insert a hash into an empty document" do
      orig_text = ""
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      map_val = ConfigValueFactory.from_any_ref({"a" => 1, "b" => 2})

      expect(config_document.set_config_value("a", map_val).render).to eq("a : {\n    \"a\" : 1,\n    \"b\" : 2\n}")
    end

    it "should successfully insert an array into an empty document" do
      orig_text = ""
      config_document = ConfigDocumentFactory.parse_string(orig_text)
      array_val = ConfigValueFactory.from_any_ref([1,2])

      expect(config_document.set_config_value("a", array_val).render).to eq("a : [\n    1,\n    2\n]")
    end
  end

  context "can insert a map parsed with ConfigValueFactory" do
    it "should successfully insert a map into a document" do
      orig_text = "{ a : b }"
      config_document = ConfigDocumentFactory.parse_string(orig_text)

      map = ConfigValueFactory.from_any_ref({"a" => 1, "b" => 2})
      expect(config_document.set_config_value("a", map).render).to eq("{ a : {\n     \"a\" : 1,\n     \"b\" : 2\n } }")
    end
  end
end