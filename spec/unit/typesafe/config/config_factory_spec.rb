require 'spec_helper'
require 'hocon/config_factory'
require 'hocon/config_render_options'

describe Hocon::ConfigFactory do
  let(:output) { File.read("#{FIXTURE_DIR}/parse_render/output.conf") }
  let(:render_options) { Hocon::ConfigRenderOptions.defaults }

  before do
    render_options.origin_comments = false
    render_options.json = false
  end

  RSpec.shared_examples "parsing" do
    it "should make the config data available as a map" do
      expect(conf.root.unwrapped).to eq(
        {:foo => {
          :bar => {
              :baz => 42,
              :abracadabra => "hi",
              :yahoo => "yippee",
              :boom => [1, 2, {:derp => "duh"}, 4]
          }}})
    end

    it "should render the config data to a string with comments intact" do
      expect(conf.root.render(render_options)).to eq(output)
    end

    it "should generate the same conf data via re-parsing the rendered output" do
      conf2 = Hocon::ConfigFactory.parse_file("#{FIXTURE_DIR}/parse_render/output.conf")
      expect(conf2.root.render(render_options)).to eq(output)
    end
  end

  context "parsing a HOCON string" do
    let(:string) { File.open("#{FIXTURE_DIR}/parse_render/input.conf").read }
    let(:conf) { Hocon::ConfigFactory.parse_string(string) }
    include_examples "parsing"
  end

  context "parsing a .conf file" do
    let(:conf) { Hocon::ConfigFactory.parse_file("#{FIXTURE_DIR}/parse_render/input.conf") }
    include_examples "parsing"
  end
end
