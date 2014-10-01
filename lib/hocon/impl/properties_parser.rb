require 'hocon/impl'
require 'hocon/config_error'
require 'hocon/impl/config_impl'

class Hocon::Impl::PropertiesParser
  def from_path_map(origin, path_map, converted_from_properties)
    # First, build a list of paths that will have values, either string or
    # object values.
    scope_paths = Set.new
    value_paths = Set.new
    path_map.each_key do |path|
      value_paths.add(path)

      next_path = path.parent
      while not next_path.nil? do
        scope_paths.add(next_path)
        next_path = next_path.parent
      end
    end

    if converted_from_properties
      # If any string values are also objects containing other values,
      # drop those string values - objects "win".
      value_paths = value_paths - scope_paths
    else
      # If we didn't start out as properties, then this is an error.
      value_paths.each do |path|
        if scope_paths.include?(path)
          raise ConfigBugOrBrokenError.new("In the map, path '#{path.render}' occurs as both" +
                                           " the parent object of a value and as a value. Because Map " +
                                           "has no defined ordering, this is a broken situation.", nil)
        end
      end
    end

    # Create maps for the object-valued values.
    root = Hash.new
    scopes = Hash.new

    value_paths.each do |path|
      parent_path = path.parent
      parent = (not parent_path.nil?) ? scopes[parent_path] : root

      last = path.last
      raw_value = path_map.get(path)
      if converted_from_properties
        if raw_value.is_a?(String)
          value = Hocon::Impl::ConfigString.new(origin, raw_value)
        else
          value = nil
        end
      else
        value = Hocon::Impl::ConfigImpl.from_any_ref_impl(path_map[path], origin, Hocon::Impl::FromMapMode::KEYS_ARE_PATHS)
      end
      if not value.nil?
        parent[last, value]
      end
    end

    # Make a list of scope paths from longest to shortest, so children go
    # before parents.
    sorted_scope_paths = Array.new
    sorted_scope_paths = sorted_scope_paths + scope_paths
    sorted_scope_paths.sort! do |a,b|
      b.length <=> a.length
    end

    # Create ConfigObject for each scope map, working from children to
    # parents to avoid modifying any already-created ConfigObject. This is
    # where we need the sorted list.
    sorted_scope_paths.each do |scope_path|
      scope = scopes[scope_path]

      parent_path = scope_path.parent
      parent = (not parent_path.nil?) ? scopes[parent_path] : root

      o = Hocon::Impl::SimpleConfigObject.new(origin, scope, Hocon::Impl::ResolveStatus::RESOLVED, false)
      parent[scope_path.last, o]
    end

    Hocon::Impl::SimpleConfigObject.new(origin, root, Hocon::Impl::ResolveStatus::RESOLVED, false)
  end
end