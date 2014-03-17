require 'hocon/impl'

class Hocon::Impl::SimpleIncludeContext
  def initialize(parseable)
    @parseable = parseable
  end
end