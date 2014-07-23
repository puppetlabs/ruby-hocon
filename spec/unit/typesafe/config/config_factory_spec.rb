require 'spec_helper'
require 'hocon/config_factory'
require 'hocon/config_render_options'

describe Hocon::ConfigFactory do
  context "parsing a .conf file" do
    conf = Hocon::ConfigFactory.parse_file("#{FIXTURE_DIR}/parse_render/input.conf")
    output = File.read("#{FIXTURE_DIR}/parse_render/output.conf")
    render_options = Hocon::ConfigRenderOptions.defaults
    render_options.origin_comments = false
    render_options.json = false

    it "should make the config data available as a map" do
      expect(conf.root.unwrapped).to eq(
        {:foo => {
          :bar => {
              :baz => 42,
              :abracadabra => "hi",
              :yahoo => "yippee",
              :boom => [1, 2, {:derp => "duh"}, 4],
              :empty => []
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
end
