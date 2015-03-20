# encoding: utf-8

require 'spec_helper'
require 'hocon'
require 'test_utils'


describe Hocon::Impl::Path do
  Path = Hocon::Impl::Path

  ####################
  # Path Equality
  ####################
  context "Check path equality" do
    # note: foo.bar is a single key here
    let(:key_a) { Path.new_key("foo.bar") }
    let(:same_as_key_a) { Path.new_key("foo.bar") }
    let(:different_key) { Path.new_key("hello") }

    # Here foo.bar is two elements
    let(:two_elements) { Path.new_path("foo.bar") }
    let(:same_as_two_elements) { Path.new_path("foo.bar") }

    context "key_a equals a path of the same name" do
      let(:first_object) { key_a }
      let(:second_object) { TestUtils.path("foo.bar") }
      include_examples "object_equality"
    end

    context "two_elements equals a path with those two elements" do
      let(:first_object) { two_elements}
      let(:second_object) { TestUtils.path("foo", "bar") }
      include_examples "object_equality"
    end

    context "key_a equals key_a" do
      let(:first_object) { key_a }
      let(:second_object) { key_a }
      include_examples "object_equality"
    end

    context "key_a equals same_as_key_a" do
      let(:first_object) { key_a }
      let(:second_object) { same_as_key_a }
      include_examples "object_equality"
    end

    context "key_a not equal to different_key" do
      let(:first_object) { key_a }
      let(:second_object) { different_key }
      include_examples "object_inequality"
    end

    context "key_a not equal to the two_elements path" do
      let(:first_object) { key_a }
      let(:second_object) { two_elements }
      include_examples "object_inequality"
    end

    context "two_elements path equals same_as_two_elements path" do
      let(:first_object) { two_elements}
      let(:second_object) { same_as_two_elements }
      include_examples "object_equality"
    end
  end

  ####################
  # Testing to_s
  ####################
  context "testing to_s" do
    it "should find to_s returning the correct strings" do
      expect("Path(foo)").to eq(TestUtils.path("foo").to_s)
      expect("Path(foo.bar)").to eq(TestUtils.path("foo", "bar").to_s)
      expect('Path(foo."bar*")').to eq(TestUtils.path("foo", "bar*").to_s)
      expect('Path("foo.bar")').to eq(TestUtils.path("foo.bar").to_s)
    end
  end

  ####################
  # Render
  ####################
  context "testing .render" do
    context "rendering simple one element case" do
      let(:expected) { "foo" }
      let(:path) { TestUtils.path("foo") }
      include_examples "path_render_test"
    end

    context "rendering simple two element case" do
      let(:expected) { "foo.bar" }
      let(:path) { TestUtils.path("foo", "bar") }
      include_examples "path_render_test"
    end

    context "rendering non safe char in an element" do
      let(:expected) { 'foo."bar*"' }
      let(:path) { TestUtils.path("foo", "bar*") }
      include_examples "path_render_test"
    end

    context "rendering period in an element" do
      let(:expected) { '"foo.bar"' }
      let(:path) { TestUtils.path("foo.bar") }
      include_examples "path_render_test"
    end

    context "rendering hyphen in element" do
      let(:expected) { "foo-bar" }
      let(:path) { TestUtils.path("foo-bar") }
      include_examples "path_render_test"
    end

    context "rendering hyphen in element" do
      let(:expected) { "foo_bar" }
      let(:path) { TestUtils.path("foo_bar") }
      include_examples "path_render_test"
    end

    context "rendering element starting with a hyphen" do
      let(:expected) { "-foo" }
      let(:path) { TestUtils.path("-foo") }
      include_examples "path_render_test"
    end

    context "rendering element starting with a number" do
      let(:expected) { "10foo" }
      let(:path) { TestUtils.path("10foo") }
      include_examples "path_render_test"
    end

    context "rendering empty elements" do
      let(:expected) { '"".""' }
      let(:path) { TestUtils.path("", "") }
      include_examples "path_render_test"
    end

    context "rendering element with internal space" do
      let(:expected) { '"foo bar"' }
      let(:path) { TestUtils.path("foo bar") }
      include_examples "path_render_test"
    end

    context "rendering leading and trailing spaces" do
      let(:expected) { '" foo "' }
      let(:path) { TestUtils.path(" foo ") }
      include_examples "path_render_test"
    end

    context "rendering trailing space only" do
      let(:expected) { '"foo "' }
      let(:path) { TestUtils.path("foo ") }
      include_examples "path_render_test"
    end

    context "rendering number with decimal point" do
      let(:expected) { "1.2" }
      let(:path) { TestUtils.path("1", "2") }
      include_examples "path_render_test"
    end

    context "rendering number with multiple decimal points" do
      let(:expected) { "1.2.3.4" }
      let(:path) { TestUtils.path("1", "2", "3", "4") }
      include_examples "path_render_test"
    end
  end

  context "test that paths made from a list of Path objects equal paths made from a list of strings" do
    it "should find a path made from a list of one path equal to a path from one string" do
      path_from_path_list = Path.from_path_list([TestUtils.path("foo")])
      expected_path = TestUtils.path("foo")

      expect(path_from_path_list).to eq(expected_path)
    end

    it "should find a path made from a list of multiple paths equal to that list of strings" do
      path_from_path_list = Path.from_path_list([TestUtils.path("foo", "bar"),
                                                 TestUtils.path("baz", "boo")])
      expected_path = TestUtils.path("foo", "bar", "baz", "boo")

      expect(path_from_path_list).to eq(expected_path)
    end
  end

  context "prepending paths" do
    it "should find prepending a single path works" do
      prepended_path = TestUtils.path("bar").prepend(TestUtils.path("foo"))
      expected_path = TestUtils.path("foo", "bar")

      expect(prepended_path).to eq(expected_path)
    end

    it "should find prepending multiple paths works" do
      prepended_path = TestUtils.path("c", "d").prepend(TestUtils.path("a", "b"))
      expected_path = TestUtils.path("a", "b", "c", "d")

      expect(prepended_path).to eq(expected_path)
    end
  end

  context "path length" do
    it "should find length of single part path to be 1" do
      path = TestUtils.path("food")
      expect(path.length).to eq(1)
    end

    it "should find length of two part path to be 2" do
      path = TestUtils.path("foo", "bar")
      expect(path.length).to eq(2)

    end
  end

  context "parent paths" do
    it "should find parent of single level path to be nil" do
      path = TestUtils.path("a")

      expect(path.parent).to be_nil
    end

    it "should find parent of a.b to be a" do
      path = TestUtils.path("a", "b")
      parent = TestUtils.path("a")

      expect(path.parent).to eq(parent)
    end

    it "should find parent of a.b.c to be a.b" do
      path = TestUtils.path("a", "b", "c")
      parent = TestUtils.path("a", "b")

      expect(path.parent).to eq(parent)
    end
  end

  context "path last method" do
    it "should find last of single level path to be itself" do
      path = TestUtils.path("a")

      expect(path.last).to eq("a")
    end

    it "should find last of a.b to be b" do
      path = TestUtils.path("a", "b")

      expect(path.last).to eq("b")
    end
  end

  context "invalid paths" do
    it "should catch exception from empty path" do
      bad_path = ""
      expect { Path.new_path(bad_path) }.to raise_error(Hocon::ConfigError::ConfigBadPathError)
    end

    it "should catch exception from path '..'" do
      bad_path = ".."
      expect { Path.new_path(bad_path) }.to raise_error(Hocon::ConfigError::ConfigBadPathError)
    end
  end
end
