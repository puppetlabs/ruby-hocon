require 'typesafe/config/impl'

class Typesafe::Config::Impl::SimpleIncludeContext
  def initialize(parseable)
    @parseable = parseable
  end
end