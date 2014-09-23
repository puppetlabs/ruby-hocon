require 'spec_helper'
require 'hocon/config_factory'
require 'hocon/config_render_options'

describe Hocon::ConfigFactory do
  let(:render_options) { Hocon::ConfigRenderOptions.defaults }

  before do
    render_options.origin_comments = false
    render_options.json = false
  end

  shared_examples_for "config_factory_parsing" do
    let(:input_file)  { "#{FIXTURE_DIR}/parse_render/#{example[:name]}/input.conf" }
    let(:output_file) { "#{FIXTURE_DIR}/parse_render/#{example[:name]}/output.conf" }
    let(:expected)    { example[:hash] }
    let(:reparsed)    { Hocon::ConfigFactory.parse_file("#{FIXTURE_DIR}/parse_render/#{example[:name]}/output.conf") }
    let(:output)      { File.read("#{output_file}") }

    it "should make the config data available as a map" do
      expect(conf.root.unwrapped).to eq(expected)
    end

    it "should render the config data to a string with comments intact" do
      expect(conf.root.render(render_options)).to eq(output)
    end

    it "should generate the same conf data via re-parsing the rendered output" do
      expect(reparsed.root.render(render_options)).to eq(output)
    end
  end

  shared_examples_for "config_value_retrieval_single_value" do
    it "should allow you to get a value for a specific configuration setting" do
      expect(conf.get_value(setting).transform_to_string).to eq(expected_setting)
    end
  end

  shared_examples_for "config_value_retrieval_config_list" do
    it "should allow you to get a value for a setting whose value is a data structure" do
      expect(conf.get_value(setting).
                 render_value_to_sb(StringIO.new, 2, nil,
                                    Hocon::ConfigRenderOptions.new(false, false, false, false)).
                 string).to eq(expected_setting)
    end
  end



  context "example1" do
    let(:example) { EXAMPLE1 }
    let(:setting) { "foo.bar.yahoo" }
    let (:expected_setting) { "yippee" }

    context "parsing a HOCON string" do
      let(:string) { File.open(input_file).read }
      let(:conf) { Hocon::ConfigFactory.parse_string(string) }
      include_examples "config_factory_parsing"
      include_examples "config_value_retrieval_single_value"
    end

    context "parsing a .conf file" do
      let(:conf) { Hocon::ConfigFactory.parse_file(input_file) }
      include_examples "config_factory_parsing"
      include_examples "config_value_retrieval_single_value"
    end
  end

  context "example2" do
    let(:example) { EXAMPLE2 }
    let(:setting) { "jruby-puppet.jruby-pools" }
    let (:expected_setting) { "[{environment=production}]" }

    context "parsing a HOCON string" do
      let(:string) { File.open(input_file).read }
      let(:conf) { Hocon::ConfigFactory.parse_string(string) }
      include_examples "config_factory_parsing"
      include_examples "config_value_retrieval_config_list"
    end

    context "parsing a .conf file" do
      let(:conf) { Hocon::ConfigFactory.parse_file(input_file) }
      include_examples "config_factory_parsing"
      include_examples "config_value_retrieval_config_list"
    end
  end
end
