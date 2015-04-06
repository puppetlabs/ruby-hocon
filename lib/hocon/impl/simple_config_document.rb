# encoding: utf-8

require 'hocon/impl'
require 'hocon/parser/config_document'
require 'hocon/impl/config_document_parser'

class Hocon::Impl::SimpleConfigDocument
  require Hocon::Parser::ConfigDocument

  def initialize(parsed_node, parse_options)
    @config_node_tree = parsed_node
    @parse_options = parse_options
  end

  def set_value(path, new_value)
    origin = Hocon::Impl::SimpleConfigOrigin.new_simple("single value parsing")
    reader = StringIO.new(new_value)
    tokens = Hocon::Impl::Tokenizer.tokenize(origin, reader, @parse_options.syntax)
    parsed_value = Hocon::Impl::ConfigDocumentParser.parse_value(tokens, origin, @parse_options)
    reader.close

    self.class.new(@config_node_tree.set_value(path, parsed_value, @parse_options.syntax), @parse_options)
  end

  def set_config_value(path, new_value)
    set_value(path, new_value.render)
  end

  def remove_value(path)
    self.class.new(@config_node_tree.set_value(path, nil, @parse_options.syntax), @parse_options)
  end

  def has_value?(path)
    @config_node_tree.has_value(path)
  end

  def render
    @config_node_tree.render
  end

  def ==(other)
    other.class.ancestors.include?(Hocon::Parser::ConfigDocument) && render == other.render
  end

  def hash
    render.hash
  end
end