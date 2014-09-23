require 'hocon/impl'
require 'hocon/impl/simple_includer'
require 'hocon/config_error'

class Hocon::Impl::ConfigImpl
  @default_includer = Hocon::Impl::SimpleIncluder.new

  ConfigNotResolvedError = Hocon::ConfigError::ConfigNotResolvedError

  def self.default_includer
    @default_includer
  end

  def self.improve_not_resolved(what, original)
    new_message = "#{what.render} has not been resolved, you need to call Config#resolve, see API docs for Config#resolve"
    if new_message == original.get_message
      return original
    else
      return ConfigNotResolvedError.new(new_message, original)
    end
  end
end