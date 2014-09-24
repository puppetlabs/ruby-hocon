require 'spec_helper'
require 'hocon/config_factory'
require 'hocon/config_render_options'

describe Hocon::ConfigFactory do
  let(:render_options) { Hocon::ConfigRenderOptions.defaults }

  before do
    render_options.origin_comments = false
    render_options.json = false
  end

  shared_examples_for "config_value_retrieval_single_value" do
    let(:input_file)  { "#{FIXTURE_DIR}/parse_render/#{example[:name]}/input.conf" }
    it "should allow you to get a value for a specific configuration setting" do
      expect(conf.get_value(setting).transform_to_string).to eq(expected_setting)
    end
  end

  shared_examples_for "config_value_retrieval_config_list" do
    let(:input_file)  { "#{FIXTURE_DIR}/parse_render/#{example[:name]}/input.conf" }
    it "should allow you to get a value for a setting whose value is a data structure" do
      expect(conf.get_value(setting).
                 render_value_to_sb(StringIO.new, 2, nil,
                                    Hocon::ConfigRenderOptions.new(false, false, false, false)).
                 string).to eq(expected_setting)
    end
  end

  shared_examples_for "has_path_check" do
    let(:input_file) { "#{FIXTURE_DIR}/parse_render/#{example[:name]}/input.conf" }
    it "should return true if a path exists" do
      expect(conf.has_path(setting)).to eql(true)
    end

    it "should return false if a path does not exist" do
      expect(conf.has_path(false_setting)).to eql(false)
    end
  end

  context "example1" do
    let(:example) { EXAMPLE1 }
    let(:setting) { "foo.bar.yahoo" }
    let (:expected_setting) { "yippee" }
    let (:false_setting) { "non-existent" }

    context "parsing a .conf file" do
      let(:conf) { Hocon::ConfigFactory.parse_file(input_file) }
      include_examples "config_value_retrieval_single_value"
      include_examples "has_path_check"
    end
  end

  context "example2" do
    let(:example) { EXAMPLE2 }
    let(:setting) { "jruby-puppet.jruby-pools" }
    let (:expected_setting) { "[{environment=production}]" }
    let (:false_setting) { "jruby-puppet-false" }

    context "parsing a .conf file" do
      let(:conf) { Hocon::ConfigFactory.parse_file(input_file) }
      include_examples "config_value_retrieval_config_list"
      include_examples "has_path_check"
    end
  end
end
