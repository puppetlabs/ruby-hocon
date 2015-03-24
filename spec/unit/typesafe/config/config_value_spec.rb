require 'spec_helper'
require 'hocon'
require 'test_utils'

require 'hocon/impl/config_delayed_merge'
require 'hocon/impl/config_delayed_merge_object'
require 'hocon/config_error'



SimpleConfigOrigin = Hocon::Impl::SimpleConfigOrigin
SimpleConfigObject = Hocon::Impl::SimpleConfigObject
SimpleConfigList = Hocon::Impl::SimpleConfigList
SubstitutionExpression = Hocon::Impl::SubstitutionExpression
ConfigReference = Hocon::Impl::ConfigReference
ConfigConcatenation = Hocon::Impl::ConfigConcatenation
ConfigDelayedMerge = Hocon::Impl::ConfigDelayedMerge
ConfigDelayedMergeObject = Hocon::Impl::ConfigDelayedMergeObject
ConfigNotResolvedError = Hocon::ConfigError::ConfigNotResolvedError
ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
AbstractConfigObject = Hocon::Impl::AbstractConfigObject

describe "SimpleConfigOrigin equality" do
  context "different origins with the same name should be equal" do
    let(:a) { SimpleConfigOrigin.new_simple("foo") }
    let(:same_as_a) { SimpleConfigOrigin.new_simple("foo") }
    let(:b) { SimpleConfigOrigin.new_simple("bar") }

    context "a equals a" do
      let(:first_object) { a }
      let(:second_object) { a }
      include_examples "object_equality"
    end

    context "a equals same_as_a" do
      let(:first_object) { a }
      let(:second_object) { same_as_a }
      include_examples "object_equality"
    end

    context "a does not equal b" do
      let(:first_object) { a }
      let(:second_object) { b }
      include_examples "object_inequality"
    end
  end
end

describe "ConfigInt equality" do
  context "different ConfigInts with the same value should be equal" do
    a = TestUtils.int_value(42)
    same_as_a = TestUtils.int_value(42)
    b = TestUtils.int_value(43)

    context "a equals a" do
      let(:first_object) { a }
      let(:second_object) { a }
      include_examples "object_equality"
    end

    context "a equals same_as_a" do
      let(:first_object) { a }
      let(:second_object) { same_as_a }
      include_examples "object_equality"
    end

    context "a does not equal b" do
      let(:first_object) { a }
      let(:second_object) { b }
      include_examples "object_inequality"
    end
  end
end

describe "ConfigFloat equality" do
  context "different ConfigFloats with the same value should be equal" do
    a = TestUtils.float_value(3.14)
    same_as_a = TestUtils.float_value(3.14)
    b = TestUtils.float_value(4.14)

    context "a equals a" do
      let(:first_object) { a }
      let(:second_object) { a }
      include_examples "object_equality"
    end

    context "a equals same_as_a" do
      let(:first_object) { a }
      let(:second_object) { same_as_a }
      include_examples "object_equality"
    end

    context "a does not equal b" do
      let(:first_object) { a }
      let(:second_object) { b }
      include_examples "object_inequality"
    end
  end
end

describe "ConfigFloat and ConfigInt equality" do
  context "different ConfigInts with the same value should be equal" do
    float_val = TestUtils.float_value(3.0)
    int_value = TestUtils.int_value(3)
    float_value_b = TestUtils.float_value(4.0)
    int_value_b = TestUtils.float_value(4)

    context "int equals float" do
      let(:first_object) { float_val }
      let(:second_object) { int_value }
      include_examples "object_equality"
    end

    context "ConfigFloat made from int equals float" do
      let(:first_object) { float_value_b }
      let(:second_object) { int_value_b }
      include_examples "object_equality"
    end

    context "3 doesn't equal 4.0" do
      let(:first_object) { int_value }
      let(:second_object) { float_value_b }
      include_examples "object_inequality"
    end

    context "4.0 doesn't equal 3.0" do
      let(:first_object) { int_value_b }
      let(:second_object) { float_val }
      include_examples "object_inequality"
    end
  end
end

describe "SimpleConfigObject equality" do
  context "SimpleConfigObjects made from hash maps" do
    a_map = TestUtils.config_map({a: 1, b: 2, c: 3})
    same_as_a_map = TestUtils.config_map({a: 1, b: 2, c: 3})
    b_map = TestUtils.config_map({a: 3, b: 4, c: 5})

    # different keys is a different case in the equals implementation
    c_map = TestUtils.config_map({x: 3, y: 4, z: 5})

    a = SimpleConfigObject.new(TestUtils.fake_origin, a_map)
    same_as_a = SimpleConfigObject.new(TestUtils.fake_origin, same_as_a_map)
    b = SimpleConfigObject.new(TestUtils.fake_origin, b_map)
    c = SimpleConfigObject.new(TestUtils.fake_origin, c_map)

    # the config for an equal object is also equal
    config = a.to_config

    context "a equals a" do
      let(:first_object) { a }
      let(:second_object) { a }
      include_examples "object_equality"
    end

    context "a equals same_as_a" do
      let(:first_object) { a }
      let(:second_object) { same_as_a }
      include_examples "object_equality"
    end

    context "b equals b" do
      let(:first_object) { b }
      let(:second_object) { b }
      include_examples "object_equality"
    end

    context "c equals c" do
      let(:first_object) { c }
      let(:second_object) { c }
      include_examples "object_equality"
    end

    context "a doesn't equal b" do
      let(:first_object) { a }
      let(:second_object) { b }
      include_examples "object_inequality"
    end

    context "a doesn't equal c" do
      let(:first_object) { a }
      let(:second_object) { c }
      include_examples "object_inequality"
    end

    context "b doesn't equal c" do
      let(:first_object) { b }
      let(:second_object) { c }
      include_examples "object_inequality"
    end

    context "a's config equals a's config" do
      let(:first_object) { config }
      let(:second_object) { config }
      include_examples "object_equality"
    end

    context "a's config equals same_as_a's config" do
      let(:first_object) { config }
      let(:second_object) { same_as_a.to_config }
      include_examples "object_equality"
    end

    context "a's config equals a's config computed again" do
      let(:first_object) { config }
      let(:second_object) { a.to_config }
      include_examples "object_equality"
    end

    context "a's config doesn't equal b's config" do
      let(:first_object) { config }
      let(:second_object) { b.to_config }
      include_examples "object_inequality"
    end

    context "a's config doesn't equal c's config" do
      let(:first_object) { config }
      let(:second_object) { c.to_config }
      include_examples "object_inequality"
    end

    context "a doesn't equal a's config" do
      let(:first_object) { a }
      let(:second_object) { config }
      include_examples "object_inequality"
    end

    context "b doesn't equal b's config" do
      let(:first_object) { b }
      let(:second_object) { b.to_config }
      include_examples "object_inequality"
    end
  end
end

describe "SimpleConfigList equality" do
  a_values = [1, 2, 3].map { |i| TestUtils.int_value(i) }
  a_list = SimpleConfigList.new(TestUtils.fake_origin, a_values)

  same_as_a_values = [1, 2, 3].map { |i| TestUtils.int_value(i) }
  same_as_a_list = SimpleConfigList.new(TestUtils.fake_origin, same_as_a_values)

  b_values = [4, 5, 6].map { |i| TestUtils.int_value(i) }
  b_list = SimpleConfigList.new(TestUtils.fake_origin, b_values)

  context "a_list equals a_list" do
    let(:first_object) { a_list }
    let(:second_object) { a_list }
    include_examples "object_equality"
  end

  context "a_list equals same_as_a_list" do
    let(:first_object) { a_list }
    let(:second_object) { same_as_a_list }
    include_examples "object_equality"
  end

  context "a_list doesn't equal b_list" do
    let(:first_object) { a_list }
    let(:second_object) { b_list }
    include_examples "object_inequality"
  end
end

describe "ConfigReference equality" do
  a = TestUtils.subst("foo")
  same_as_a = TestUtils.subst("foo")
  b = TestUtils.subst("bar")
  c = TestUtils.subst("foo", true)

  specify "testing values are of the right type" do
    expect(a).to be_instance_of(ConfigReference)
    expect(b).to be_instance_of(ConfigReference)
    expect(c).to be_instance_of(ConfigReference)
  end

  context "a equals a" do
    let(:first_object) { a }
    let(:second_object) { a }
    include_examples "object_equality"
  end

  context "a equals same_as_a" do
    let(:first_object) { a }
    let(:second_object) { same_as_a }
    include_examples "object_equality"
  end

  context "a doesn't equal b" do
    let(:first_object) { a }
    let(:second_object) { b }
    include_examples "object_inequality"
  end

  context "a doesn't equal c, an optional substitution" do
    let(:first_object) { a }
    let(:second_object) { c }
    include_examples "object_inequality"
  end
end

describe "ConfigConcatenation equality" do
  a = TestUtils.subst_in_string("foo")
  same_as_a = TestUtils.subst_in_string("foo")
  b = TestUtils.subst_in_string("bar")
  c = TestUtils.subst_in_string("foo", true)

  specify "testing values are of the right type" do
    expect(a).to be_instance_of(ConfigConcatenation)
    expect(b).to be_instance_of(ConfigConcatenation)
    expect(c).to be_instance_of(ConfigConcatenation)
  end

  context "a equals a" do
    let(:first_object) { a }
    let(:second_object) { a }
    include_examples "object_equality"
  end

  context "a equals same_as_a" do
    let(:first_object) { a }
    let(:second_object) { same_as_a }
    include_examples "object_equality"
  end

  context "a doesn't equal b" do
    let(:first_object) { a }
    let(:second_object) { b }
    include_examples "object_inequality"
  end

  context "a doesn't equal c, an optional substitution" do
    let(:first_object) { a }
    let(:second_object) { c }
    include_examples "object_inequality"
  end
end

describe "ConfigDelayedMerge equality" do
  s1 = TestUtils.subst("foo")
  s2 = TestUtils.subst("bar")
  a = ConfigDelayedMerge.new(TestUtils.fake_origin, [s1, s2])
  same_as_a = ConfigDelayedMerge.new(TestUtils.fake_origin, [s1, s2])
  b = ConfigDelayedMerge.new(TestUtils.fake_origin, [s2, s1])

  context "a equals a" do
    let(:first_object) { a }
    let(:second_object) { a }
    include_examples "object_equality"
  end

  context "a equals same_as_a" do
    let(:first_object) { a }
    let(:second_object) { same_as_a }
    include_examples "object_equality"
  end

  context "a doesn't equal b" do
    let(:first_object) { a }
    let(:second_object) { b }
    include_examples "object_inequality"
  end
end

describe "ConfigDelayedMergeObject equality" do
  empty = SimpleConfigObject.empty
  s1 = TestUtils.subst("foo")
  s2 = TestUtils.subst("bar")
  a = ConfigDelayedMergeObject.new(TestUtils.fake_origin, [empty, s1, s2])
  same_as_a = ConfigDelayedMergeObject.new(TestUtils.fake_origin, [empty, s1, s2])
  b = ConfigDelayedMergeObject.new(TestUtils.fake_origin, [empty, s2, s1])

  context "a equals a" do
    let(:first_object) { a }
    let(:second_object) { a }
    include_examples "object_equality"
  end

  context "a equals same_as_a" do
    let(:first_object) { a }
    let(:second_object) { same_as_a }
    include_examples "object_equality"
  end

  context "a doesn't equal b" do
    let(:first_object) { a }
    let(:second_object) { b }
    include_examples "object_inequality"
  end
end

describe "ConfigObject" do
  specify "should unwrap correctly" do
    m = SimpleConfigObject.new(TestUtils.fake_origin, TestUtils.config_map({a: 1, b: 2, c: 3}))

    expect({a: 1, b: 2, c: 3}).to eq(m.unwrapped)
  end

  specify "should implement read only map" do
    m = SimpleConfigObject.new(TestUtils.fake_origin, TestUtils.config_map({a: 1, b: 2, c: 3}))

    expect(TestUtils.int_value(1)).to eq(m[:a])
    expect(TestUtils.int_value(2)).to eq(m[:b])
    expect(TestUtils.int_value(3)).to eq(m[:c])
    expect(m[:d]).to be_nil
    # [] can take a non-string
    expect(m[[]]).to be_nil

    expect(m.has_key? :a).to be_truthy
    expect(m.has_key? :z).to be_falsey
    # has_key? can take a non-string
    expect(m.has_key? []).to be_falsey

    expect(m.has_value? TestUtils.int_value(1)).to be_truthy
    expect(m.has_value? TestUtils.int_value(10)).to be_falsey
    # has_value? can take a non-string
    expect(m.has_value? []).to be_falsey

    expect(m.empty?).to be_falsey

    expect(m.size).to eq(3)

    values = [TestUtils.int_value(1), TestUtils.int_value(2), TestUtils.int_value(3)]
    expect(values).to eq(m.values)

    keys = [:a, :b, :c]
    expect(keys).to eq(m.keys)

    expect { m["hello"] = TestUtils.int_value(41) }.to raise_error(ConfigBugOrBrokenError)
    expect { m.delete(:a) }.to raise_error(ConfigBugOrBrokenError)
  end
end

describe "ConfigList" do
  specify "should implement read only list" do
    values = ["a", "b", "c"].map { |i| TestUtils.string_value(i) }
    l = SimpleConfigList.new(TestUtils.fake_origin, values)

    expect(values[0]).to eq(l[0])
    expect(values[1]).to eq(l[1])
    expect(values[2]).to eq(l[2])

    expect(l.include? TestUtils.string_value("a")).to be_truthy
    expect(l.include_all?([TestUtils.string_value("a")])).to be_truthy
    expect(l.include_all?([TestUtils.string_value("b")])).to be_truthy
    expect(l.include_all?(values)).to be_truthy

    expect(l.index(values[1])).to eq(1)

    expect(l.empty?).to be_falsey

    expect(l.map { |v| v }).to eq(values.map { |v| v })

    expect(l.rindex(values[1])).to eq(1)

    expect(l.size).to eq(3)

    expect { l.push(TestUtils.int_value(3)) }.to raise_error(NoMethodError)
    expect { l << TestUtils.int_value(3) }.to raise_error(NoMethodError)
    expect { l.clear }.to raise_error(NoMethodError)
    expect { l.delete(TestUtils.int_value(2)) }.to raise_error(NoMethodError)
    expect { l.delete(1) }.to raise_error(NoMethodError)
    expect { l[0] = TestUtils.int_value(42) }.to raise_error(NoMethodError)
  end
end

describe "Objects throwing ConfigNotResolvedError" do
  context "ConfigSubstitution" do
    specify "should throw ConfigNotResolvedError" do
      expect{ TestUtils.subst("foo").value_type }.to raise_error(ConfigNotResolvedError)
      expect{ TestUtils.subst("foo").unwrapped }.to raise_error(ConfigNotResolvedError)
    end
  end

  context "ConfigDelayedMerge" do
    let(:dm) { ConfigDelayedMerge.new(TestUtils.fake_origin, [TestUtils.subst("a"), TestUtils.subst("b")]) }

    specify "should throw ConfigNotResolvedError" do
      expect{ dm.value_type }.to raise_error(ConfigNotResolvedError)
      expect{ dm.unwrapped }.to raise_error(ConfigNotResolvedError)
    end
  end

  context "ConfigDelayedMergeObject" do
    empty_object = SimpleConfigObject.empty
    objects = [empty_object, TestUtils.subst("a"), TestUtils.subst("b")]

    let(:dmo) { ConfigDelayedMergeObject.new(TestUtils.fake_origin, objects) }

    specify "should have value type of OBJECT" do
      expect(dmo.value_type).to eq(Hocon::ConfigValueType::OBJECT)
    end

    specify "should throw ConfigNotResolvedError" do
      expect{ dmo.unwrapped }.to raise_error(ConfigNotResolvedError)
      expect{ dmo["foo"] }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.has_key?(nil) }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.has_value?(nil) }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.each }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.empty? }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.keys }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.size }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.values }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.to_config.get_int("foo") }.to raise_error(ConfigNotResolvedError)
    end
  end
end
