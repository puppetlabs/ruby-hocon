require 'hocon/impl'
require 'hocon/config_value_type'

class Hocon::Impl::ConfigNull < Hocon::Impl::AbstractConfigValue
  def value_type
    Hocon::Impl::ConfigValueType::NULL
  end

  def unwrapped
    nil
  end

  def transform_to_string
    "null"
  end

  def render(sb, indent, atRoot, options)
    sb.append("null")
  end

  def newCopy(origin)
    ConfigNull.new(origin)
  end

end