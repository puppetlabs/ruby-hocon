# encoding: utf-8

require 'hocon'
require 'hocon/impl/config_impl'

class Hocon::ConfigValueFactory
  ConfigImpl = Hocon::Impl::ConfigImpl

  def self.from_any_ref(object, origin_description = nil)
    ConfigImpl.from_any_ref(object, origin_description)
  end

  def self.from_map(values, origin_description = nil)
    ConfigImpl.from_any_ref(values, origin_description)
  end
end
