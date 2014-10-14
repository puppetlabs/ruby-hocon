require 'hocon/impl'
require 'hocon/impl/path_builder'
require 'hocon/config_error'
require 'stringio'

class Hocon::Impl::Path

  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
  ConfigImplUtil = Hocon::Impl::ConfigImplUtil

  # this doesn't have a very precise meaning, just to reduce
  # noise from quotes in the rendered path for average cases
  def self.has_funky_chars?(s)
    length = s.length
    if length == 0
      return false
    end

    # if the path starts with something that could be a number,
    # we need to quote it because the number could be invalid,
    # for example it could be a hyphen with no digit afterward
    # or the exponent "e" notation could be mangled.
    first = s[0]
    unless first =~ /[[:alpha:]]/
      return true
    end

    s.chars.each do |c|
      unless (c =~ /[[:alnum:]]/) || (c == '-') || (c == '_')
        return true
      end
    end

    false
  end

  def initialize(first, remainder)
    @first = first
    @remainder = remainder
  end
  attr_reader :first, :remainder

  def first
    @first
  end

  def remainder
    @remainder
  end

  def parent
    if remainder.nil?
      return nil
    end

    pb = Hocon::Impl::PathBuilder.new
    p = self
    while not p.remainder.nil?
      pb.append_key(p.first)
      p = p.remainder
    end
    pb.result
  end

  def last
    p = self
    while not p.remainder.nil?
      p = p.remainder
    end
    p.first
  end

  def length
    count = 1
    p = remainder
    while not p.nil? do
      count += 1
      p = p.remainder
    end
    return count
  end

  #
  # toString() is a debugging-oriented version while this is an
  # error-message-oriented human-readable one.
  #
  def render
    sb = StringIO.new
    append_to_string_builder(sb)
    sb.string
  end

  def append_to_string_builder(sb)
    if self.class.has_funky_chars?(@first) || @first.empty?
      sb << ConfigImplUtil.render_json_string(@first)
    else
      sb << @first
    end

    unless @remainder.nil?
      sb << "."
      @remainder.append_to_string_builder(sb)
    end
  end

  def sub_path_to_end(remove_from_front)
    count = remove_from_front
    p = self
    while (not p.nil?) && count > 0 do
      count -= 1
      p = p.remainder
    end
    p
  end

  def sub_path(first_index, last_index)
    if last_index < first_index
      raise ConfigBugOrBrokenError.new("bad call to sub_path", nil)
    end
    from = sub_path_to_end(first_index)
    pb = Hocon::Impl::PathBuilder.new
    count = last_index - first_index
    while count > 0 do
      count -= 1
      pb.append_key(from.first)
      from = from.remainder
      if from.nil?
        raise ConfigBugOrBrokenError.new("sub_path last_index out of range #{last_index}", nil)
      end
    end
    pb.result
  end

  def self.new_path(path)
    Hocon::Impl::Parser.parse_path(path)
  end
end