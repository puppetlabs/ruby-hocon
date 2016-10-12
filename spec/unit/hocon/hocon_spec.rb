# encoding: utf-8

require 'spec_helper'
require 'hocon'
require 'hocon/config_render_options'
require 'hocon/config_error'
require 'hocon/config_syntax'

ConfigParseError = Hocon::ConfigError::ConfigParseError
ConfigWrongTypeError = Hocon::ConfigError::ConfigWrongTypeError

describe Hocon do
  let(:render_options) { Hocon::ConfigRenderOptions.defaults }

  before do
    render_options.origin_comments = false
    render_options.json = false
  end

  RSpec.shared_examples "hocon_parsing" do

    it "should make the config data available as a map" do
      expect(conf).to eq(expected)
    end

  end

  [EXAMPLE1, EXAMPLE2].each do |example|
    let(:input_file) { "#{FIXTURE_DIR}/parse_render/#{example[:name]}/input.conf" }
    let(:output_file) { "#{FIXTURE_DIR}/parse_render/#{example[:name]}/output.conf" }
    let(:output) { File.read("#{output_file}") }
    let(:output_nocomments_file) { "#{FIXTURE_DIR}/parse_render/#{example[:name]}/output_nocomments.conf" }
    let(:output_nocomments) { File.read("#{output_nocomments_file}") }
    let(:expected) { example[:hash] }
    # TODO 'reparsed' appears to be unused
    let(:reparsed) { Hocon::ConfigFactory.parse_file("#{FIXTURE_DIR}/parse_render/#{example[:name]}/output.conf") }

    context "loading a HOCON file" do
      let(:conf) { Hocon.load(input_file) }
      include_examples "hocon_parsing"
    end

    context "parsing a HOCON string" do
      let(:string) { File.open(input_file).read }
      let(:conf) { Hocon.parse(string) }
      include_examples "hocon_parsing"
    end
  end

  it "should fail to parse an array" do
    puts 
    expect{(Hocon.parse('[1,2,3]'))}.
      to raise_error(ConfigWrongTypeError)
  end

  it "should fail to parse an array" do
    expect{(Hocon.parse('["one", "two" "three"]'))}.
      to raise_error(ConfigWrongTypeError)
  end

  context "loading a HOCON file with a substitution" do
    conf = Hocon.load("#{FIXTURE_DIR}/parse_render/#{EXAMPLE3[:name]}/input.conf")
    expected = EXAMPLE3[:hash]
    it "should successfully resolve the substitution" do
      expect(conf).to eq(expected)
    end
  end

  context "loading a file with an unknown extension" do
    context "without specifying the config format" do
      it "should raise an error" do
        expect {
          Hocon.load("#{FIXTURE_DIR}/hocon/by_extension/cat.test")
        }.to raise_error(ConfigParseError, /Unrecognized file extension '.test'/)
      end
    end

    context "while specifying the config format" do
      it "should parse properly if the config format is correct" do
        expect(Hocon.load("#{FIXTURE_DIR}/hocon/by_extension/cat.test",
                          {:syntax => Hocon::ConfigSyntax::HOCON})).
            to eq({"meow" => "cats"})
        expect(Hocon.load("#{FIXTURE_DIR}/hocon/by_extension/cat.test-json",
                          {:syntax => Hocon::ConfigSyntax::HOCON})).
            to eq({"meow" => "cats"})
      end
      it "should parse properly if the config format is compatible" do
        expect(Hocon.load("#{FIXTURE_DIR}/hocon/by_extension/cat.test-json",
                          {:syntax => Hocon::ConfigSyntax::JSON})).
            to eq({"meow" => "cats"})
      end
      it "should raise an error if the config format is incompatible" do
        expect {
          Hocon.load("#{FIXTURE_DIR}/hocon/by_extension/cat.test",
                     {:syntax => Hocon::ConfigSyntax::JSON})
        }.to raise_error(ConfigParseError, /Document must have an object or array at root/)
      end
    end
  end

  context "loading config that includes substitutions" do
    it "should be able to `load` from a file" do
      expect(Hocon.load("#{FIXTURE_DIR}/hocon/with_substitution/subst.conf")).
          to eq({"a" => true, "b" => true})
    end
    it "should be able to `parse` from a string" do
      expect(Hocon.parse(File.read("#{FIXTURE_DIR}/hocon/with_substitution/subst.conf"))).
          to eq({"a" => true, "b" => true})
    end
  end


end

