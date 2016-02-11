# encoding: utf-8

require 'spec_helper'
require 'hocon'
require 'hocon/config_render_options'

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

  context "loading a HOCON file with a substitution" do
    conf = Hocon.load("#{FIXTURE_DIR}/parse_render/#{EXAMPLE3[:name]}/input.conf")
    expected = EXAMPLE3[:hash]
    it "should successfully resolve the substitution" do
      expect(conf).to eq(expected)
    end
  end
end

