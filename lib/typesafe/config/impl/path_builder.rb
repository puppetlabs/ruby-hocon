require 'typesafe/config/impl'
require 'typesafe/config/impl/path'

class Typesafe::Config::Impl::PathBuilder
  Path = Typesafe::Config::Impl::Path

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
        remainder = Path.new(key, remainder)
      end
      @result = remainder
    end
    @result
  end
end