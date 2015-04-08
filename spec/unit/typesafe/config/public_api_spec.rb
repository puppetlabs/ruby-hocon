# encoding: utf-8

require 'spec_helper'
require 'test_utils'
require 'hocon'
require 'hocon/config_factory'
require 'hocon/config_value_factory'
require 'hocon/impl/config_delayed_merge_object'
require 'hocon/impl/replaceable_merge_stack'
require 'hocon/config_util'

# Note: Skipping many tests that rely on java's System.getProperties functionality,
#   which lets you access things like "os.name", "java.vendor", and "user.home"
# Also skipping

ConfigFactory = Hocon::ConfigFactory
ConfigValueFactory = Hocon::ConfigValueFactory
SimpleConfigObject = Hocon::Impl::SimpleConfigObject
SimpleConfigList = Hocon::Impl::SimpleConfigList
ConfigUtil = Hocon::ConfigUtil

shared_examples_for "test_from_value" do
  default_value_description = "hardcoded value"

  specify "create_from made into a config value should equal the expected value" do
    expect(Hocon::ConfigValueFactory.from_any_ref(create_from)).to eq(expected_value)
  end

  specify "create_from made into a config value with origin description should equal the expected value" do
    expect(Hocon::ConfigValueFactory.from_any_ref(create_from, "foo")).to eq(expected_value)
  end

  specify "descriptions match" do
    if create_from.is_a?(Hocon::ConfigValue)
      # description is ignored for createFrom that is already a ConfigValue
      expect(Hocon::ConfigValueFactory.from_any_ref(create_from).origin.description).to eq(create_from.origin.description)
    else
      expect(Hocon::ConfigValueFactory.from_any_ref(create_from).origin.description).to eq(default_value_description)
      expect(Hocon::ConfigValueFactory.from_any_ref(create_from, "foo").origin.description).to eq("foo")
    end
  end
end

describe "basic load and get" do
  conf = ConfigFactory.load_file(TestUtils.resource_file("test01"))

  specify "should be able to see some values in the config object" do
    expect(conf.get_int("ints.fortyTwo")).to eq(42)
    child = conf.get_config("ints")

    expect(child.get_int("fortyTwo")).to eq(42)
  end
end

describe "loading JSON only" do
  options = Hocon::ConfigParseOptions.defaults.set_syntax(Hocon::ConfigSyntax::JSON)
  conf = ConfigFactory.load_file_with_parse_options(TestUtils.resource_file("test01"), options)

  specify "should be missing value specific to CONF files" do
    TestUtils.intercept(Hocon::ConfigError::ConfigMissingError) do
      conf.get_int("ints.fortyTwo")
    end
  end

  specify "should find value specific to the JSON file" do
    expect(conf.get_int("fromJson1")).to eq(1)
  end
end

describe "loading CONF only" do
  options = Hocon::ConfigParseOptions.defaults.set_syntax(Hocon::ConfigSyntax::CONF)
  conf = ConfigFactory.load_file_with_parse_options(TestUtils.resource_file("test01"), options)

  specify "should be missing value specific to JSON files" do
    TestUtils.intercept(Hocon::ConfigError::ConfigMissingError) do
      conf.get_int("fromJson1")
    end

    TestUtils.intercept(Hocon::ConfigError::ConfigMissingError) do
      conf.get_int("fromProps.one")
    end
  end

  specify "should find value specific to the CONF file" do
    expect(conf.get_int("ints.fortyTwo")).to eq(42)
  end
end

describe "ConfigFactory#load_file_with_resolve_options" do
  options = Hocon::ConfigResolveOptions.defaults
  conf = ConfigFactory.load_file_with_resolve_options(TestUtils.resource_file("test01"), options)

  specify "sanity check to make sure load_file_with_resolve_options act strange" do
    expect(conf.get_int("ints.fortyTwo")).to eq(42)
  end
end

describe "empty configs" do
  empty = ConfigFactory.empty
  empty_foo = ConfigFactory.empty("foo")

  specify "empty config is empty" do
    expect(empty.empty?).to be true
  end

  specify "empty config's origin should be 'empty config'" do
    expect(empty.origin.description).to eq("empty config")
  end

  specify "empty config with origin description is empty" do
    expect(empty_foo.empty?).to be true
  end

  specify "empty config with origin description 'foo' is having it's description set" do
    expect(empty_foo.origin.description).to eq("foo")
  end
end

describe "Creating objects with ConfigValueFactory" do
  context "from true" do
    let(:expected_value) { TestUtils.bool_value(true) }
    let(:create_from) { true }

    include_examples "test_from_value"
  end

  context "from false" do
    let(:expected_value) { TestUtils.bool_value(false) }
    let(:create_from) { false }

    include_examples "test_from_value"
  end

  context "from nil" do
    let(:expected_value) { TestUtils.null_value }
    let(:create_from) { nil }

    include_examples "test_from_value"
  end

  context "from int" do
    let(:expected_value) { TestUtils.int_value(5) }
    let(:create_from) { 5 }

    include_examples "test_from_value"
  end

  context "from float" do
    let(:expected_value) { TestUtils.double_value(3.14) }
    let(:create_from) { 3.14 }

    include_examples "test_from_value"
  end

  context "from string" do
    let(:expected_value) { TestUtils.string_value("hello world") }
    let(:create_from) { "hello world" }

    include_examples "test_from_value"
  end

  context "from empty hash" do
    let(:expected_value) { SimpleConfigObject.new(TestUtils.fake_origin, {}) }
    let(:create_from) { {} }

    include_examples "test_from_value"
  end

  context "from populated hash" do
    value_hash = TestUtils.config_map({"a" => 1, "b" => 2, "c" => 3})

    let(:expected_value) { SimpleConfigObject.new(TestUtils.fake_origin, value_hash) }
    let(:create_from) { {"a" => 1, "b" => 2, "c" => 3} }

    include_examples "test_from_value"

    specify "from_map should also work" do
      # from_map is just a wrapper around from_any_ref
      expect(ConfigValueFactory.from_map({"a" => 1, "b" => 2, "c" => 3}).origin.description).to eq("hardcoded value")
      expect(ConfigValueFactory.from_map({"a" => 1, "b" => 2, "c" => 3}, "foo").origin.description).to eq("foo")
    end
  end

  context "from empty array" do
    let(:expected_value) { SimpleConfigList.new(TestUtils.fake_origin, []) }
    let(:create_from) { [] }

    include_examples "test_from_value"
  end

  context "from populated array" do
    value_array = [1, 2, 3].map { |v| TestUtils.int_value(v) }

    let(:expected_value) { SimpleConfigList.new(TestUtils.fake_origin, value_array) }
    let(:create_from) { [1, 2, 3] }

    include_examples "test_from_value"
  end

  # Omitting tests that involve trees and iterators
  # Omitting tests using units (memory size, duration, etc)

  context "from existing Config values" do
    context "from int" do
      let(:expected_value) { TestUtils.int_value(1000) }
      let(:create_from) { TestUtils.int_value(1000) }

      include_examples "test_from_value"
    end

    context "from string" do
      let(:expected_value) { TestUtils.string_value("foo") }
      let(:create_from) { TestUtils.string_value("foo") }

      include_examples "test_from_value"
    end

    context "from hash" do
      int_map = {"a" => 1, "b" => 2, "c" => 3}
      let(:expected_value) { SimpleConfigObject.new(TestUtils.fake_origin, TestUtils.config_map(int_map)) }
      let(:create_from) { SimpleConfigObject.new(TestUtils.fake_origin, TestUtils.config_map(int_map)) }

      include_examples "test_from_value"
    end
  end

  context "from existing list of Config values" do
    int_list = [1, 2, 3].map { |v| TestUtils.int_value(v) }

    let(:expected_value) { SimpleConfigList.new(TestUtils.fake_origin, int_list) }
    let(:create_from) { int_list }

    include_examples "test_from_value"
  end
end

describe "round tripping unwrap" do
  conf = ConfigFactory.load_file(TestUtils.resource_file("test01"))

  unwrapped = conf.root.unwrapped

  rewrapped = ConfigValueFactory.from_map(unwrapped, conf.origin.description)
  reunwrapped = rewrapped.unwrapped

  specify "conf has a lot of stuff in it" do
    expect(conf.root.size).to be > 4
  end

  specify "rewrapped conf equals conf" do
    expect(rewrapped).to eq(conf.root)
  end

  specify "reunwrapped conf equals unwrapped conf" do
    expect(unwrapped).to eq(reunwrapped)
  end
end

# Omitting Tests (and functionality) for ConfigFactory.parse_map until I know if it's
# a priority

describe "default parse options" do
  def check_not_found(e)
    ["No such", "not found", "were found"].any? { |string| e.message.include?(string)}
  end

  let(:defaults) { Hocon::ConfigParseOptions::defaults }

  specify "allow missing == true" do
    expect(defaults.allow_missing?).to be true
  end

  specify "includer == nil" do
    expect(defaults.includer).to be_nil
  end

  specify "origin description == nil" do
    expect(defaults.origin_description).to be_nil
  end

  specify "syntax == nil" do
    expect(defaults.syntax).to be_nil
  end

  context "allow missing with ConfigFactory#parse_file" do
    specify "nonexistant conf throws error when allow_missing? == false" do
      allow_missing_false = Hocon::ConfigParseOptions::defaults.set_allow_missing(false)

      e = TestUtils.intercept(Hocon::ConfigError::ConfigIOError) do
        ConfigFactory.parse_file(TestUtils.resource_file("nonexistant.conf"), allow_missing_false)
      end

      expect(check_not_found(e)).to be true
    end

    specify "nonexistant conf returns empty conf when allow_missing? == false" do
      allow_missing_true = Hocon::ConfigParseOptions::defaults.set_allow_missing(true)

      conf = ConfigFactory.parse_file(TestUtils.resource_file("nonexistant.conf"), allow_missing_true)

      expect(conf.empty?).to be true
    end
  end

  context "allow missing with ConfigFactory#parse_file_any_syntax" do
    specify "nonexistant conf throws error when allow_missing? == false" do
      allow_missing_false = Hocon::ConfigParseOptions::defaults.set_allow_missing(false)

      e = TestUtils.intercept(Hocon::ConfigError::ConfigIOError) do
        ConfigFactory.parse_file_any_syntax(TestUtils.resource_file("nonexistant"), allow_missing_false)
      end

      expect(check_not_found(e)).to be true
    end

    specify "nonexistant conf returns empty conf when allow_missing? == false" do
      allow_missing_true = Hocon::ConfigParseOptions::defaults.set_allow_missing(true)

      conf = ConfigFactory.parse_file_any_syntax(TestUtils.resource_file("nonexistant"), allow_missing_true)

      expect(conf.empty?).to be true
    end
  end

  # Omitting ConfigFactory.prase_resources_any_syntax since we're not supporting it
  context "allow missing shouldn't mess up includes" do
    # test03.conf contains some nonexistent includes. check that
    # setAllowMissing on the file (which is not missing) doesn't
    # change that the includes are allowed to be missing.
    # This can break because some options might "propagate" through
    # to includes, but we don't want them all to do so.

    allow_missing_true = Hocon::ConfigParseOptions::defaults.set_allow_missing(true)
    allow_missing_false = Hocon::ConfigParseOptions::defaults.set_allow_missing(false)

    conf = ConfigFactory.parse_file(TestUtils.resource_file("test03.conf"), allow_missing_false)
    conf2 = ConfigFactory.parse_file(TestUtils.resource_file("test03.conf"), allow_missing_true)

    specify "conf should have stuff from test01.conf" do
      expect(conf.get_int("test01.booleans")).to eq(42)
    end

    specify "both confs should be equal regardless of allow_missing being true or false" do
      expect(conf).to eq(conf2)
    end
  end
end

# Omitting test that creates a subclass of ConfigIncluder to record everything that's
# included by a .conf file. It's complex and we've decided the functionality is well
# tested elsewhere and right now it isn't worth the effort.

describe "string parsing" do
  specify "should parse correctly" do
    conf = ConfigFactory.parse_string("{ a : b }", Hocon::ConfigParseOptions.defaults)

    expect(conf.get_string("a")).to eq("b")
  end
end


# Omitting tests for parse_file_any_syntax in the interests of time since this has already
# been tested above

# Omitting classpath tests

describe "config_utils" do
  # This is to test the public wrappers around ConfigImplUtils

  specify "can join and split paths" do
    expect(ConfigUtil.join_path("", "a", "b", "$")).to eq("\"\".a.b.\"$\"")
    expect(ConfigUtil.join_path_from_list(["", "a", "b", "$"])).to eq("\"\".a.b.\"$\"")
    expect(ConfigUtil.split_path("\"\".a.b.\"$\"")).to eq(["", "a", "b", "$"])
  end

  specify "should throw errors on invalid paths" do
    TestUtils.intercept(Hocon::ConfigError) do
      ConfigUtil.split_path("$")
    end

    TestUtils.intercept(Hocon::ConfigError) do
      # no args
      ConfigUtil.join_path
    end

    TestUtils.intercept(Hocon::ConfigError) do
      # empty list
      ConfigUtil.join_path_from_list([])
    end
  end

  specify "should quote strings correctly" do
    expect(ConfigUtil.quote_string("")).to eq("\"\"")
    expect(ConfigUtil.quote_string("a")).to eq("\"a\"")
    expect(ConfigUtil.quote_string("\n")).to eq("\"\\n\"")
  end
end

# Omitting tests that use class loaders

describe "detecting cycles" do
  specify "should detect a cycle" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigParseError) do
      ConfigFactory.load_file(TestUtils.resource_file("cycle.conf"))
    end

    # Message mentioning cycle
    expect(e.message).to include("include statements nested")
  end
end

describe "including from list" do
  # We would ideally make this case NOT throw an exception but we need to do some work
  # to get there, see https://github.com/typesafehub/config/issues/160
  specify "should throw error when trying to include from list" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigParseError) do
      ConfigFactory.load_file(TestUtils.resource_file("include-from-list.conf"))
    end

    # Message mentioning current implementation limitations
    expect(e.message).to include("limitation")
  end
end

# Omitting tests using System.getProperty since it's java specific

# Omitting serialization tests since we aren't supporting it

describe "using some values without resolving" do
  conf = ConfigFactory.parse_string("a=42,b=${NOPE}")

  specify "should be able to use some values without resolving" do
    expect(conf.get_int("a")).to eq(42)
  end

  specify "unresolved value should throw error" do
    TestUtils.intercept(Hocon::ConfigError::ConfigNotResolvedError) do
      conf.get_int("b")
    end
  end
end

describe "include file statements" do
  conf = ConfigFactory.parse_file(TestUtils.resource_file("file-include.conf"))

  specify "should find values from each included file" do
    expect(conf.get_int("base")).to eq(41)
    expect(conf.get_int("foo")).to eq(42)
    expect(conf.get_int("bar")).to eq(43)
    # these two do not work right now, because we do not
    # treat the filename as relative to the including file
    # if file() is specified, so `include file("bar-file.conf")`
    # fails.
    #assertEquals("got bar-file.conf", 44, conf.getInt("bar-file"))
    #assertEquals("got subdir/baz.conf", 45, conf.getInt("baz"))
  end

  specify "should not find certain paths" do
    expect(conf.has_path?("bar-file")).to be false
    expect(conf.has_path?("baz")).to be false
  end
end

describe "Config#has_path_or_null" do
  conf = ConfigFactory.parse_string("x.a=null,x.b=42")

  specify "has_path_or_null returns correctly" do
    # hasPath says false for null
    expect(conf.has_path?("x.a")).to be false
    # hasPathOrNull says true for null
    expect(conf.has_path_or_null?("x.a")).to be true

    # hasPath says true for non-null
    expect(conf.has_path?("x.b")).to be true
    # hasPathOrNull says true for non-null
    expect(conf.has_path_or_null?("x.b")).to be true

    # hasPath says false for missing
    expect(conf.has_path?("x.c")).to be false
    # hasPathOrNull says false for missing
    expect(conf.has_path_or_null?("x.c")).to be false

    # hasPath says false for missing under null
    expect(conf.has_path?("x.a.y")).to be false
    # hasPathOrNull says false for missing under null
    expect(conf.has_path_or_null?("x.a.y")).to be false

    # hasPath says false for missing under missing
    expect(conf.has_path?("x.c.y")).to be false
    # hasPathOrNull says false for missing under missing
    expect(conf.has_path_or_null?("x.c.y")).to be false

  end
end

describe "Config#get_is_null" do
  conf = ConfigFactory.parse_string("x.a=null,x.b=42")

  specify "should return whether or not values are null correctly" do
    expect(conf.is_null?("x.a")).to be true
    expect(conf.is_null?("x.b")).to be false
  end

  specify "should throw error for missing values" do
    TestUtils.intercept(Hocon::ConfigError::ConfigMissingError) do
      conf.is_null?("x.c")
    end
  end

  specify "should throw error for missing underneal null" do
    TestUtils.intercept(Hocon::ConfigError::ConfigMissingError) do
      conf.is_null?("x.a.y")
    end
  end

  specify "should throw error for missing underneath missing" do
    TestUtils.intercept(Hocon::ConfigError::ConfigMissingError) do
      conf.is_null?("x.c.y")
    end
  end
end
