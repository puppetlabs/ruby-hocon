# encoding: utf-8

require_relative '../hocon'
require_relative '../hocon/config_value'

#
# Subtype of {@link ConfigValue} representing an object (AKA dictionary or map)
# value, as in JSON's curly brace <code>{ "a" : 42 }</code> syntax.
#
# <p>
# An object may also be viewed as a {@link Config} by calling
# {@link ConfigObject#toConfig()}.
#
# <p>
# {@code ConfigObject} implements {@code java.util.Map<String, ConfigValue>} so
# you can use it like a regular Java map. Or call {@link #unwrapped()} to
# unwrap the map to a map with plain Java values rather than
# {@code ConfigValue}.
#
# <p>
# Like all {@link ConfigValue} subtypes, {@code ConfigObject} is immutable.
# This makes it threadsafe and you never have to create "defensive copies." The
# mutator methods from {@link java.util.Map} all throw
# {@link java.lang.UnsupportedOperationException}.
#
# <p>
# The {@link ConfigValue#valueType} method on an object returns
# {@link ConfigValueType#OBJECT}.
#
# <p>
# In most cases you want to use the {@link Config} interface rather than this
# one. Call {@link #toConfig()} to convert a {@code ConfigObject} to a
# {@code Config}.
#
# <p>
# The API for a {@code ConfigObject} is in terms of keys, while the API for a
# {@link Config} is in terms of path expressions. Conceptually,
# {@code ConfigObject} is a tree of maps from keys to values, while a
# {@code Config} is a one-level map from paths to values.
#
# <p>
# Use {@link ConfigUtil#joinPath} and {@link ConfigUtil#splitPath} to convert
# between path expressions and individual path elements (keys).
#
# <p>
# A {@code ConfigObject} may contain null values, which will have
# {@link ConfigValue#valueType()} equal to {@link ConfigValueType#NULL}. If
# {@link ConfigObject#get(Object)} returns Java's null then the key was not
# present in the parsed file (or wherever this value tree came from). If
# {@code get("key")} returns a {@link ConfigValue} with type
# {@code ConfigValueType#NULL} then the key was set to null explicitly in the
# config file.
#
# <p>
# <em>Do not implement interface {@code ConfigObject}</em>; it should only be
# implemented by the config library. Arbitrary implementations will not work
# because the library internals assume a specific concrete implementation.
# Also, this interface is likely to grow new methods over time, so third-party
# implementations will break.
#
module Hocon::ConfigObject
  include Hocon::ConfigValue

    #
    # Converts this object to a {@link Config} instance, enabling you to use
    # path expressions to find values in the object. This is a constant-time
    # operation (it is not proportional to the size of the object).
    #
    # @return a {@link Config} with this object as its root
    #
    def to_config
      raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of ConfigObject should provide their own implementation of `to_config` (#{self.class})"
    end

    #
    # Recursively unwraps the object, returning a map from String to whatever
    # plain Java values are unwrapped from the object's values.
    #
    # @return a {@link java.util.Map} containing plain Java objects
    #
    def unwrapped
      raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of ConfigObject should provide their own implementation of `unwrapped` (#{self.class})"
    end

    def with_fallback(other)
      raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of ConfigObject should provide their own implementation of `with_fallback` (#{self.class})"
    end

    #
    # Gets a {@link ConfigValue} at the given key, or returns null if there is
    # no value. The returned {@link ConfigValue} may have
    # {@link ConfigValueType#NULL} or any other type, and the passed-in key
    # must be a key in this object (rather than a path expression).
    #
    # @param key
    #            key to look up
    #
    # @return the value at the key or null if none
    #
    def get(key)
      raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of ConfigObject should provide their own implementation of `get` (#{self.class})"
    end

    #
    # Clone the object with only the given key (and its children) retained; all
    # sibling keys are removed.
    #
    # @param key
    #            key to keep
    # @return a copy of the object minus all keys except the one specified
    #
    def with_only_key(key)
      raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of ConfigObject should provide their own implementation of `with_only_key` (#{self.class})"
    end

    #
    # Clone the object with the given key removed.
    #
    # @param key
    #            key to remove
    # @return a copy of the object minus the specified key
    #
    def without_key(key)
      raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of ConfigObject should provide their own implementation of `without_key` (#{self.class})"
    end

    #
    # Returns a {@code ConfigObject} based on this one, but with the given key
    # set to the given value. Does not modify this instance (since it's
    # immutable). If the key already has a value, that value is replaced. To
    # remove a value, use {@link ConfigObject#withoutKey(String)}.
    #
    # @param key
    #            key to add
    # @param value
    #            value at the new key
    # @return the new instance with the new map entry
    #
    def with_value(key, value)
      raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of ConfigObject should provide their own implementation of `with_value` (#{self.class})"
    end

    def with_origin(origin)
      raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of ConfigObject should provide their own implementation of `with_origin` (#{self.class})"
    end

end
