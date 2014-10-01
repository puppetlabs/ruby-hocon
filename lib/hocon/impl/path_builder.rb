require 'hocon/impl'
require 'hocon/impl/path'

class Hocon::Impl::PathBuilder

  def initialize
    @keys = []
    @result = nil
  end

  def check_can_append
    if @result
      raise ConfigBugError, "Adding to PathBuilder after getting result"
    end
  end

  def append_key(key)
    check_can_append
    @keys.push(key)
  end

  def result
    # note: if keys is empty, we want to return null, which is a valid
    # empty path
    if @result.nil?
      remainder = nil
      while !@keys.empty?
        key = @keys.pop
        remainder = Hocon::Impl::Path.new(key, remainder)
      end
      @result = remainder
    end
    @result
  end
end