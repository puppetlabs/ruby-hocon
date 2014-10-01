require 'hocon/impl'
require 'hocon/impl/abstract_config_value'
require 'hocon/impl/simple_config'
require 'hocon/config_object'
require 'hocon/config_value_type'
require 'hocon/impl/resolve_status'
require 'hocon/impl/simple_config_origin'
require 'hocon/config_error'
require 'hocon/impl/config_impl'

class Hocon::Impl::AbstractConfigObject < Hocon::Impl::AbstractConfigValue
  include Hocon::ConfigObject

  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
  ConfigNotResolvedError = Hocon::ConfigError::ConfigNotResolvedError

  def initialize(origin)
    super(origin)
    @config = Hocon::Impl::SimpleConfig.new(self)
  end

  def to_config
    @config
  end

  def to_fallback_value
    self
  end

  def value_type
    Hocon::ConfigValueType::OBJECT
  end

  def new_copy(origin)
    new_copy_with_status(resolve_status, origin)
  end

  def merge_origins(stack)
    if stack.empty?
      raise ConfigBugError, "can't merge origins on empty list"
    end
    origins = []
    first_origin = nil
    num_merged = 0
    stack.each do |v|
      if first_origin.nil?
        first_origin = v.origin
      end

      if (v.is_a?(Hocon::Impl::AbstractConfigObject)) &&
          (v.resolve_status == Hocon::Impl::ResolveStatus::RESOLVED) &&
          v.empty?
        # don't include empty files or the .empty()
        # config in the description, since they are
        # likely to be "implementation details"
      else
        origins.push(v.origin)
        num_merged += 1
      end
    end

    if num_merged == 0
      # the configs were all empty, so just use the first one
      origins.push(first_origin)
    end

    Hocon::Impl::SimpleConfigOrigin.merge_origins(origins)
  end

  def peek_assuming_resolved(key, original_path)
    begin
      attempt_peek_with_partial_resolve(key)
    rescue ConfigNotResolvedError => e
      raise Hocon::Impl::ConfigImpl.improve_not_resolved(original_path, e)
    end
  end

  def peek_path(path)
    begin
      return peek_path_impl(self, path, nil)
    rescue ConfigNotResolvedError => e
      raise ConfigBugOrBrokenError.new("NotPossibleToResolve happened though we had no ResolveContext in peek_path", nil)
    end
  end

  def peek_path_impl(me, path, context)
    begin
      if not context.nil?
        partially_resolved = context.restrict(path).resolve(me)
        if partially_resolved.is_a?(self.class)
          return peek_path_impl(partially_resolved, path, nil)
        else
          raise ConfigBugOrBrokenError.new(
              "resolved object to non-object #{me} to #{partially_resolved}", nil)
        end
      else
        remainder = path.remainder
        v = me.attempt_peek_with_partial_resolve(path.first)
        if remainder.nil?
          return v
        else
          if v.is_a?(self.class)
            return peek_path_impl(v, remainder, nil)
          else
            return nil
          end
        end
      end
    rescue ConfigNotResolvedError => e
      raise Hocon::Impl::ConfigImpl.improve_not_resolved(path, e)
    end
  end
end