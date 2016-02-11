# encoding: utf-8

require 'spec_helper'
require 'hocon/config_factory'
require 'hocon/config_render_options'
require 'hocon/config_error'

def get_comment_config_hash(config_string)
  split_config_string = config_string.split("\n")
  r = Regexp.new('^\s*#')

  previous_string_comment = false
  hash = {}
  comment_list = []

  split_config_string.each do |s|
    if r.match(s)
      comment_list << s
      previous_string_comment = true
    else
      if previous_string_comment
        hash[s] = comment_list
        comment_list = []
      end
      previous_string_comment = false
    end
  end
  return hash
end

describe Hocon::ConfigFactory do
  let(:render_options) { Hocon::ConfigRenderOptions.defaults }

  before do
    render_options.origin_comments = false
    render_options.json = false
  end

  shared_examples_for "config_factory_parsing" do
    let(:input_file)  { "#{FIXTURE_DIR}/parse_render/#{example[:name]}/input#{extension}" }
    let(:output_file) { "#{FIXTURE_DIR}/parse_render/#{example[:name]}/output.conf" }
    let(:expected)    { example[:hash] }
    let(:reparsed)    { Hocon::ConfigFactory.parse_file("#{output_file}") }
    let(:output)      { File.read("#{output_file}") }

    it "should make the config data available as a map" do
      expect(conf.root.unwrapped).to eq(expected)
    end

    it "should render the config data to a string with comments intact" do
      rendered_conf = conf.root.render(render_options)
      rendered_conf_comment_hash = get_comment_config_hash(rendered_conf)
      output_comment_hash = get_comment_config_hash(output)

      expect(rendered_conf_comment_hash).to eq(output_comment_hash)
    end

    it "should generate the same conf data via re-parsing the rendered output" do
      expect(reparsed.root.unwrapped).to eq(expected)
    end
  end

  context "example1" do
    let(:example) { EXAMPLE1 }
    let (:extension) { ".conf" }

    context "parsing a HOCON string" do
      let(:string) { File.open(input_file).read }
      let(:conf) { Hocon::ConfigFactory.parse_string(string) }
      include_examples "config_factory_parsing"
    end

    context "parsing a .conf file" do
      let(:conf) { Hocon::ConfigFactory.parse_file(input_file) }
      include_examples "config_factory_parsing"
    end
  end

  context "example2" do
    let(:example) { EXAMPLE2 }
    let (:extension) { ".conf" }

    context "parsing a HOCON string" do
      let(:string) { File.open(input_file).read }
      let(:conf) { Hocon::ConfigFactory.parse_string(string) }
      include_examples "config_factory_parsing"
    end

    context "parsing a .conf file" do
      let(:conf) { Hocon::ConfigFactory.parse_file(input_file) }
      include_examples "config_factory_parsing"
    end
  end

  context "example3" do
    let (:example) { EXAMPLE3 }
    let (:extension) { ".conf" }

    context "loading a HOCON file with substitutions" do
      let(:conf) { Hocon::ConfigFactory.load_file(input_file) }
      include_examples "config_factory_parsing"
    end
  end

  context "example4" do
    let(:example) { EXAMPLE4 }
    let (:extension) { ".json" }

    context "parsing a .json file" do
      let (:conf) { Hocon::ConfigFactory.parse_file(input_file) }
      include_examples "config_factory_parsing"
    end
  end

  context "example5" do
    it "should raise a ConfigParseError when given an invalid .conf file" do
      expect{Hocon::ConfigFactory.parse_string("abcdefg")}.to raise_error(Hocon::ConfigError::ConfigParseError)
    end
  end
end
