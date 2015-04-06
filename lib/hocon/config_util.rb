require 'hocon/impl/config_impl_util'


# Contains static utility methods
class Hocon::ConfigUtil
  def self.quote_string(string)
    Hocon::Impl::ConfigImplUtil.render_json_string(string)
  end

  def self.join_path(*elements)
    Hocon::Impl::ConfigImplUtil.join_path(*elements)
  end

  def self.split_path(path)
    Hocon::Impl::ConfigImplUtil.split_path(path)
  end
end
