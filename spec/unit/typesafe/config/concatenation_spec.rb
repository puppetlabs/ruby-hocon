# encoding: utf-8

require 'test_utils'

describe "concatenation" do

  it "string concat, no substitutions" do
    conf = TestUtils.parse_config(' a :  true "xyz" 123 foo  ').resolve
    expect(conf.get_string("a")).to eq("true xyz 123 foo")
  end

  it "trivial string concat" do
    conf = TestUtils.parse_config(" a : ${x}foo, x = 1 ").resolve
    expect(conf.get_string("a")).to eq("1foo")
  end

  it "two substitutions and string concat" do
    conf = TestUtils.parse_config(" a : ${x}foo${x}, x = 1 ").resolve
    expect(conf.get_string("a")).to eq("1foo1")
  end

  it "string concat cannot span lines" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigParseError) {
      TestUtils.parse_config(" a : ${x}
        foo, x = 1 ")
    }
    expect(e.message).to include("not be followed")
    expect(e.message).to include("','")
  end

  it "no objects in string concat" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigWrongTypeError) {
      TestUtils.parse_config(" a : abc { x : y } ")
    }
    expect(e.message).to include("Cannot concatenate")
    expect(e.message).to include("abc")
    expect(e.message).to include('{"x":"y"}')
  end

  it "no object concat with nil" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigWrongTypeError) {
      TestUtils.parse_config(" a : null { x : y } ")
    }
    expect(e.message).to include("Cannot concatenate")
    expect(e.message).to include("null")
    expect(e.message).to include('{"x":"y"}')
  end
end
