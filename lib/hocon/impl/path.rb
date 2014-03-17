require 'hocon/impl'
require 'stringio'

class Hocon::Impl::Path
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
end