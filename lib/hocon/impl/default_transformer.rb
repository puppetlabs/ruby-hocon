require 'hocon/impl'
require 'hocon/config_value_type'

class Hocon::Impl::DefaultTransformer

  ConfigValueType = Hocon::ConfigValueType

  def self.transform(value, requested)
    if value.value == ConfigValueType::STRING
      s = value.unwrapped
      case requested
        when NUMBER
          begin
            v = Integer(s)
            return ConfigInt.new(value.origin, v, s)
          rescue ArgumentError
            # try Float
          end
          begin
            v = Float(s)
            return ConfigFloat.new(value.origin, v, s)
          rescue ArgumentError
            # oh well.
          end
        when NULL
          if s == "null"
            return ConfigNull.new(value.origin)
          end
        when BOOLEAN
          if s == "true" || s == "yes" || s == "on"
            return ConfigBoolean.new(value.origin, true)
          elsif s == "false" || s == "no" || s == "off"
            return ConfigBoolean.new(value.origin, false)
          end
        when LIST
          # can't go STRING to LIST automatically
        when OBJECT
          # can't go STRING to OBJECT automatically
        when STRING
          # no-op STRING to STRING
      end
    elsif requested == ConfigValueType::STRING
      # if we converted null to string here, then you wouldn't properly
      # get a missing-value error if you tried to get a null value
      # as a string.
      case value.value_type
        # NUMBER case removed since you can't fallthrough in a ruby case statement
        when BOOLEAN
          return ConfigString.new(value.origin, value.transform_to_string)
        when NULL
          # want to be sure this throws instead of returning "null" as a
          # string
        when OBJECT
          # no OBJECT to STRING automatically
        when LIST
          # no LIST to STRING automatically
        when STRING
          # no-op STRING to STRING
      end
    elsif requested == ConfigValueType::LIST && value.value_type == ConfigValueType::OBJECT
      # attempt to convert an array-like (numeric indices) object to a
      # list. This would be used with .properties syntax for example:
      # -Dfoo.0=bar -Dfoo.1=baz
      # To ensure we still throw type errors for objects treated
      # as lists in most cases, we'll refuse to convert if the object
      # does not contain any numeric keys. This means we don't allow
      # empty objects here though :-/
      o = value
      values = Hash.new
      values
      o.keys.each do |key|
        begin
          i = Integer(key, 10)
          if i < 0
            next
          end
          values[key] = i
        rescue ArgumentError
          next
        end
      end
      if not values.empty?
        entry_list = values.to_a
        # sort by numeric index
        entry_list.sort! {|a,b| b[0] <=> a[0]}
        # drop the indices (we allow gaps in the indices, for better or
        # worse)
        list = Array.new
        entry_list.each do |entry|
          list.push(entry[1])
        end
        return SimpleConfigList.new(value.origin, list)
      end
    end
    value
  end
end