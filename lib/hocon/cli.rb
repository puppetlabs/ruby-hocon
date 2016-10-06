require 'optparse'
require 'hocon'
require 'hocon/config_factory'
require 'hocon/parser/config_document_factory'

module Hocon::CLI
  # List of valid subcommands
  SUBCOMMANDS = ['get', 'set', 'unset']

  # Parses the command line flags and argument
  # Returns a options hash with values for each option and argument
  def self.parse_args(args)
    options = {}
    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: hocon [--file HOCON_FILE] {get,set,unset} PATH [VALUE]'

      opts.on('-i', '--in-file HOCON_FILE', 'HOCON file to read/modify. If omitted, STDIN assumed') do |in_file|
        options[:in_file] = in_file
      end

      opts.on('-o', '--out-file HOCON_FILE', 'File to be written to. If omitted, STDOUT assumed') do |out_file|
        options[:out_file] = out_file
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end
    # parse! returns the argument list minus all the flags it found
    remaining_args = opt_parser.parse!(args)

    no_subcommand_error(opt_parser) unless remaining_args.size > 0

    # Assume the first arg is the subcommand
    subcommand = remaining_args.shift
    options[:subcommand] = subcommand

    case subcommand
      when 'set'
        subcommand_arguments_error(subcommand, opt_parser) unless remaining_args.size >= 2
        options[:path] = remaining_args.shift
        options[:new_value] = remaining_args.shift

      when 'get', 'unset'
        subcommand_arguments_error(subcommand, opt_parser) unless remaining_args.size >= 1
        options[:path] = remaining_args.shift

      else
        invalid_subcommand_error(subcommand, opt_parser)
    end

    options
  end

  # Main entry point into the script
  # Calls the appropriate subcommand
  def self.main(opts)
    case opts[:subcommand]
      when 'get'
        puts get_main(opts)
      when 'set'
        puts set_main(opts)
      when 'unset'
        puts unset_main(opts)
    end

    exit(0)
  end

  # Entry point for the 'get' subcommand
  # Prints the value at the path given on the command line
  def self.get_main(opts)
    config = get_hocon_config(opts)

    config.get_any_ref(opts[:path])
  end

  # Entry point for the 'set' subcommand
  # Prints the HOCON config after adding/replacing the value at the given path
  # with the given value
  def self.set_main(opts)
    config_doc = get_hocon_doc(opts)
    modified_config_doc = config_doc.set_value(opts[:path], opts[:new_value])

    modified_config_doc.render
  end

  # Entry point for the 'unset' subcommand
  # Prints the HOCON config after removing the value at the given path
  def self.unset_main(opts)
    config_doc = get_hocon_doc(opts)
    modified_config_doc = config_doc.remove_value(opts[:path])

    modified_config_doc.render
  end

  # Returns a Config object from the file given on the command line
  # or from STDIN if no file is specified
  def self.get_hocon_config(opts)
    if opts[:in_file]
      file_path = File.expand_path(opts[:in_file])
      config = Hocon::ConfigFactory.parse_file(file_path)
    else
      config = Hocon::ConfigFactory.parse_string(STDIN.read)
    end

    config
  end

  # Returns a ConfigDocument object from the file given on the command line
  # or from STDIN if no file is specified
  def self.get_hocon_doc(opts)
    if opts[:in_file]
      file_path = File.expand_path(opts[:in_file])
      config_doc = Hocon::Parser::ConfigDocumentFactory.parse_file(file_path)
    else
      config_doc = Hocon::Parser::ConfigDocumentFactory.parse_string(STDIN.read)
    end

    config_doc
  end

  # Print an error message and usage, then exit the program
  def self.exit_with_error(opt_parser, message)
    STDERR.puts opt_parser
    STDERR.puts message
    exit(1)
  end

  # Exits with an error saying there aren't enough arguments found for a given
  # subcommand. Prints the usage
  def self.subcommand_arguments_error(subcommand, opt_parser)
    error_message = "Too few arguments for '#{subcommand}' subcommand"
    exit_with_error(opt_parser, error_message)
  end

  # Exits with an error for when no subcommand is supplied on the command line.
  # Prints the usage
  def self.no_subcommand_error(opt_parser)
    error_message = "Must specify subcommand from [#{SUBCOMMANDS.join(', ')}]"
    exit_with_error(opt_parser, error_message)
  end

  # Exits with an error for when a subcommand doesn't exist. Prints the usage
  def self.invalid_subcommand_error(subcommand, opt_parser)
    error_message = "Invalid subcommand '#{subcommand}', must be one of [#{SUBCOMMANDS.join(', ')}]"
    exit_with_error(opt_parser, error_message)
  end
end
