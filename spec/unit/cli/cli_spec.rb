# encoding: utf-8

require 'spec_helper'
require 'test_utils'


describe Hocon::CLI do
  ####################
  # Argument Parsing
  ####################
  context 'argument parsing' do
    it 'should find all the flags and arguments' do
      args = %w(-i foo -o bar set some.path some_value --json)
      expected_options = {
        in_file: 'foo',
        out_file: 'bar',
        subcommand: 'set',
        path: 'some.path',
        new_value: 'some_value',
        json: true
      }
      expect(Hocon::CLI.parse_args(args)).to eq(expected_options)
    end

    it 'should set -i and -o to -f if given' do
      args = %w(-f foo set some.path some_value)
      expected_options = {
        file: 'foo',
        in_file: 'foo',
        out_file: 'foo',
        subcommand: 'set',
        path: 'some.path',
        new_value: 'some_value'
      }
      expect(Hocon::CLI.parse_args(args)).to eq(expected_options)
    end
  end

  context 'subcommands' do
    hocon_text =
'foo.bar {
  baz = 42
  array = [1, 2, 3]
  hash: {key: value}
}'

    context 'do_get()' do
      it 'should get simple values' do
        options = {path: 'foo.bar.baz'}
        expect(Hocon::CLI.do_get(options, hocon_text)).to eq('42')
      end

      it 'should work with arrays' do
        options = {path: 'foo.bar.array'}
        expected = "[\n    1,\n    2,\n    3\n]"
        expect(Hocon::CLI.do_get(options, hocon_text)).to eq(expected)
      end

      it 'should work with hashes' do
        options = {path: 'foo.bar.hash'}
        expected = "key: value\n"
        expect(Hocon::CLI.do_get(options, hocon_text)).to eq(expected)
      end

      it 'should output json if specified' do
        options = {path: 'foo.bar.hash', json: true}

        # Note that this is valid json, while the test above is not
        expected = "{\n    \"key\": \"value\"\n}\n"
        expect(Hocon::CLI.do_get(options, hocon_text)).to eq(expected)
      end

      it 'should throw a MissingPathError if the path does not exist' do
        options = {path: 'not.a.path'}
        expect {Hocon::CLI.do_get(options, hocon_text)}
            .to raise_error(Hocon::CLI::MissingPathError)
      end

      it 'should throw a MissingPathError if the path leads into an array' do
        options = {path: 'foo.array.1'}
        expect {Hocon::CLI.do_get(options, hocon_text)}
            .to raise_error(Hocon::CLI::MissingPathError)
      end

      it 'should throw a MissingPathError if the path leads into a string' do
        options = {path: 'foo.hash.key.value'}
        expect {Hocon::CLI.do_get(options, hocon_text)}
            .to raise_error(Hocon::CLI::MissingPathError)
      end
    end

    context 'do_set()' do
      it 'should overwrite values' do
        options = {path: 'foo.bar.baz', new_value: 'pi'}
        expected = hocon_text.sub(/42/, 'pi')
        expect(Hocon::CLI.do_set(options, hocon_text)).to eq(expected)
      end

      it 'should create new nested values' do
        options = {path: 'new.nested.path', new_value: 'hello'}
        expected = "new: {\n  nested: {\n    path: hello\n  }\n}"
        # No config is supplied, so it will need to add new nested hashes
        expect(Hocon::CLI.do_set(options, '')).to eq(expected)
      end

      it 'should allow arrays to be set' do
        options = {path: 'my_array', new_value: '[1, 2, 3]'}
        expected = 'my_array: [1, 2, 3]'
        expect(Hocon::CLI.do_set(options, '')).to eq(expected)
      end

      it 'should allow arrays in strings to be set as strings' do
        options = {path: 'my_array', new_value: '"[1, 2, 3]"'}
        expected = 'my_array: "[1, 2, 3]"'
        expect(Hocon::CLI.do_set(options, '')).to eq(expected)
      end

      it 'should allow hashes to be set' do
        do_set_options = {path: 'my_hash', new_value: '{key: value}'}
        do_set_expected = 'my_hash: {key: value}'
        do_set_result = Hocon::CLI.do_set(do_set_options, '')
        expect(do_set_result).to eq(do_set_expected)

        # Make sure it can be parsed again and be seen as a real hash
        do_get_options = {path: 'my_hash.key'}
        do_get_expected = 'value'
        expect(Hocon::CLI.do_get(do_get_options, do_set_result)).to eq(do_get_expected)
      end

      it 'should allow hashes to be set as strings' do
        do_set_options = {path: 'my_hash', new_value: '"{key: value}"'}
        do_set_expected = 'my_hash: "{key: value}"'
        do_set_result = Hocon::CLI.do_set(do_set_options, '')
        expect(do_set_result).to eq(do_set_expected)

        # Make sure it can't be parsed again and be seen as a real hash
        do_get_options = {path: 'my_hash.key'}
        expect{Hocon::CLI.do_get(do_get_options, do_set_result)}
            .to raise_error(Hocon::CLI::MissingPathError)
      end
    end

    context 'do_unset()' do
      it 'should remove values' do
        options = {path: 'foo.bar.baz'}
        expected = hocon_text.sub(/baz = 42/, '')
        expect(Hocon::CLI.do_unset(options, hocon_text)).to eq(expected)
      end

      it 'should throw a MissingPathError if the path does not exist' do
        options = {path: 'fake.path'}
        expect{Hocon::CLI.do_unset(options, hocon_text)}
            .to raise_error(Hocon::CLI::MissingPathError)
      end
    end
  end
end
