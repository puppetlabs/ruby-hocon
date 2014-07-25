require 'spec_helper'
require 'hocon/config_factory'
require 'hocon/config_render_options'

describe Hocon::ConfigFactory do
  let(:render_options) { Hocon::ConfigRenderOptions.defaults }

  before do
    render_options.origin_comments = false
    render_options.json = false
  end

  RSpec.shared_examples "config_factory_parsing" do
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

  [EXAMPLE1, EXAMPLE2].each do |example|
    let(:input_file) { "#{FIXTURE_DIR}/parse_render/#{example[:name]}/input.conf" }
    let(:output_file) { "#{FIXTURE_DIR}/parse_render/#{example[:name]}/output.conf" }
    let(:expected) { example[:hash] }
    let(:reparsed) { Hocon::ConfigFactory.parse_file("#{FIXTURE_DIR}/parse_render/#{example[:name]}/output.conf") }
    let(:output) { File.read("#{output_file}") }

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
end

