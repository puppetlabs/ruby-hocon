# encoding: utf-8

require 'test_utils'


describe "concatenation" do
  it "string concatenation with no substitutions" do
    conf = TestUtils.parse_config(' a :  true "xyz" 123 foo  ').resolve
    expect(conf.get_string("a")).to eq("true xyz 123 foo")
  end

  it "trivial string concatenation" do
    conf = TestUtils.parse_config(" a : ${x}foo, x = 1 ").resolve
    expect(conf.get_string("a")).to eq("1foo")
  end
end

