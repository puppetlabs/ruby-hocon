require 'hocon'
require 'hocon/impl/config_impl'

class Hocon::ConfigValueFactory
  ConfigImpl = Hocon::Impl::ConfigImpl

  def self.from_any_ref(object, origin_description)
    ConfigImpl.from_any_ref(object, origin_description)
  end
end