# encoding: utf-8

require 'spec_helper'
require 'hocon/config_value_factory'
require 'hocon/config_render_options'
require 'hocon/config_error'

describe Hocon::ConfigValueFactory do
  let(:render_options) { Hocon::ConfigRenderOptions.defaults }

  before do
    render_options.origin_comments = false
    render_options.json = false
  end

  context "converting objects to ConfigValue using ConfigValueFactory" do
    it "should convert true into a ConfigBoolean" do
      value = Hocon::ConfigValueFactory.from_any_ref(true, nil)
      expect(value).to be_instance_of(Hocon::Impl::ConfigBoolean)
      expect(value.unwrapped).to eql(true)
    end

    it "should convert false into a ConfigBoolean" do
      value = Hocon::ConfigValueFactory.from_any_ref(false, nil)
      expect(value).to be_instance_of(Hocon::Impl::ConfigBoolean)
      expect(value.unwrapped).to eql(false)
    end

    it "should convert nil into a ConfigNull object" do
      value = Hocon::ConfigValueFactory.from_any_ref(nil, nil)
      expect(value).to be_instance_of(Hocon::Impl::ConfigNull)
      expect(value.unwrapped).to be_nil
    end

    it "should convert an string into a ConfigString object" do
      value = Hocon::ConfigValueFactory.from_any_ref("Hello, World!", nil)
      expect(value).to be_a(Hocon::Impl::ConfigString)
      expect(value.unwrapped).to eq("Hello, World!")
    end

    it "should convert an integer into a ConfigInt object" do
      value = Hocon::ConfigValueFactory.from_any_ref(123, nil)
      expect(value).to be_instance_of(Hocon::Impl::ConfigInt)
      expect(value.unwrapped).to eq(123)
    end

    it "should convert a double into a ConfigDouble object" do
      value = Hocon::ConfigValueFactory.from_any_ref(123.456, nil)
      expect(value).to be_instance_of(Hocon::Impl::ConfigDouble)
      expect(value.unwrapped).to eq(123.456)
    end

    it "should convert a map into a SimpleConfigObject" do
      map = {"a" => 1, "b" => 2, "c" => 3}
      value = Hocon::ConfigValueFactory.from_any_ref(map, nil)
      expect(value).to be_instance_of(Hocon::Impl::SimpleConfigObject)
      expect(value.unwrapped).to eq(map)
    end

    it "should convert symbol keys in a map to string keys" do
      orig_map = {a: 1, b: 2, c: {a: 1, b: 2, c: {a: 1}}}
      map = {"a" => 1, "b" => 2, "c"=>{"a"=>1, "b"=>2, "c"=>{"a"=>1}}}
      value = Hocon::ConfigValueFactory.from_any_ref(orig_map, nil)
      expect(value).to be_instance_of(Hocon::Impl::SimpleConfigObject)
      expect(value.unwrapped).to eq(map)

      value = Hocon::ConfigValueFactory.from_map(orig_map, nil)
      expect(value).to be_instance_of(Hocon::Impl::SimpleConfigObject)
      expect(value.unwrapped).to eq(map)
    end

    it "should not parse maps with non-string and non-symbol keys" do
      map = {1 => "a", 2 => "b"}
      expect{ Hocon::ConfigValueFactory.from_any_ref(map, nil) }.to raise_error(Hocon::ConfigError::ConfigBugOrBrokenError)
    end

    it "should convert an Enumerable into a SimpleConfigList" do
      list = [1, 2, 3, 4, 5]
      value = Hocon::ConfigValueFactory.from_any_ref(list, nil)
      expect(value).to be_instance_of(Hocon::Impl::SimpleConfigList)
      expect(value.unwrapped).to eq(list)
    end
  end

end
