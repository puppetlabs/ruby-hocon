require 'typesafe/config/impl'
require 'typesafe/config/config_syntax'
require 'typesafe/config/impl/config_impl'
require 'typesafe/config/impl/simple_include_context'
require 'typesafe/config/impl/simple_config_object'
require 'typesafe/config/impl/simple_config_origin'
require 'typesafe/config/impl/tokenizer'
require 'typesafe/config/impl/parser'

class Typesafe::Config::Impl::Parseable
  class ParseableFile < Typesafe::Config::Impl::Parseable
    def initialize(file_path, options)
      @input = file_path
      post_construct(options)
    end

    def guess_syntax
      Typesafe::Config::Impl::Parseable.syntax_from_extension(File.basename(@input))
    end

    def create_origin
      Typesafe::Config::Impl::SimpleConfigOrigin.new_file(@input)
    end

    def reader
      self
    end

    def open
      if block_given?
        File.open(@input) do |f|
          yield f
        end
      else
        File.open(@input)
      end
    end
  end

  def self.new_file(file_path, options)
    ParseableFile.new(file_path, options)
  end

  def options
    @initial_options
  end

  def include_context
    @include_context
  end

  def self.force_parsed_to_object(value)
    if value.is_a? Typesafe::Config::Impl::AbstractConfigObject
      value
    else
      raise ConfigWrongTypeError.new(value.origin, "", "object at file root",
                                     value.value_type.name)
    end
  end

  def parse
    self.class.force_parsed_to_object(parse_value(options))
  end

  def parse_value(base_options)
    # note that we are NOT using our "initialOptions",
    # but using the ones from the passed-in options. The idea is that
    # callers can get our original options and then parse with different
    # ones if they want.
    options = fixup_options(base_options)

    # passed-in options can override origin
    origin =
        if options.origin_description
          Typesafe::Config::Impl::SimpleConfigOrigin.new_simple(options.origin_description)
        else
          @initial_origin
        end
    parse_value_from_origin(origin, options)
  end


  private

  def self.syntax_from_extension(filename)
    case File.extname(filename)
      when ".json"
        Typesafe::Config::ConfigSyntax::JSON
      when ".conf"
        Typesafe::Config::ConfigSyntax::CONF
      when ".properties"
        Typesafe::Config::ConfigSyntax::PROPERTIES
      else
        nil
    end
  end

  def post_construct(base_options)
    @initial_options = fixup_options(base_options)
    @include_context = Typesafe::Config::Impl::SimpleIncludeContext.new(self)
    if @initial_options.origin_description
      @initial_origin = SimpleConfigOrigin.new_simple(@initial_options.origin_description)
    else
      @initial_origin = create_origin
    end
  end

  def fixup_options(base_options)
    syntax = base_options.syntax
    if !syntax
      syntax = guess_syntax
    end
    if !syntax
      syntax = Typesafe::Config::ConfigSyntax.CONF
    end

    modified = base_options.with_syntax(syntax)
    modified = modified.append_includer(Typesafe::Config::Impl::ConfigImpl.default_includer)
    modified = modified.with_includer(Typesafe::Config::Impl::SimpleIncluder.make_full(modified.includer))

    modified
  end

  def parse_value_from_origin(origin, final_options)
    begin
      raw_parse_value(origin, final_options)
    rescue IOError => e
      if final_options.allow_missing?
        Typesafe::Config::Impl::SimpleConfigObject.empty_missing(origin)
      else
        raise ConfigIOError.new(origin, "#{e.class.name}: #{e.message}", e)
      end
    end
  end

  # this is parseValue without post-processing the IOException or handling
  # options.getAllowMissing()
  def raw_parse_value(origin, final_options)
    ## TODO: if we were going to support loading from URLs, this
    ##  method would need to deal with the content-type.

    reader.open { |io|
      raw_parse_value_from_io(io, origin, final_options)
    }
  end

  def raw_parse_value_from_io(io, origin, final_options)
    tokens = Typesafe::Config::Impl::Tokenizer.tokenize(origin, io, final_options.syntax)
    Typesafe::Config::Impl::Parser.parse(tokens, origin, final_options, include_context)
  end
end