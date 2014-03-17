require 'hocon'

class Hocon::ConfigParseOptions
  attr_accessor :syntax, :origin_description, :allow_missing, :includer

  def self.defaults
    self.new(nil, nil, true, nil)
  end

  def initialize(syntax, origin_description, allow_missing, includer)
    @syntax = syntax
    @origin_description = origin_description
    @allow_missing = allow_missing
    @includer = includer
  end

  def allow_missing?
    @allow_missing
  end

  def with_syntax(syntax)
    if @syntax == syntax
      self
    else
      Hocon::ConfigParseOptions.new(syntax,
                                    @origin_description,
                                    @allow_missing,
                                    @includer)
    end
  end

  def with_includer(includer)
    if @includer == includer
      self
    else
      Hocon::ConfigParseOptions.new(@syntax,
                                    @origin_description,
                                    @allow_missing,
                                    includer)
    end
  end

  def append_includer(includer)
    if @includer == includer
      self
    elsif @includer
      with_includer(@includer.with_fallback(includer))
    else
      with_includer(includer)
    end
  end

end