# encoding: utf-8

require 'hocon'
require 'hocon/impl'
require 'hocon/impl/abstract_config_value'
require 'hocon/impl/resolve_source'

class Hocon::Impl::ConfigReference < Hocon::Impl::AbstractConfigValue
  NotPossibleToResolve = Hocon::Impl::AbstractConfigValue::NotPossibleToResolve

  attr_reader :expr

  def initialize(origin, expr, prefix_length = 0)
    super(origin)
    @expr = expr
    @prefix_length = prefix_length
  end

  # ConfigReference should be a firewall against NotPossibleToResolve going
  # further up the stack; it should convert everything to ConfigException.
  # This way it 's impossible for NotPossibleToResolve to "escape" since
  # any failure to resolve has to start with a ConfigReference.
  def resolve_substitutions(context, source)
    new_context = context.add_cycle_marker(self)
    begin
      result_with_path = source.lookup_subst(new_context, @expr, @prefix_length)
      new_context = result_with_path.result.context

      if result_with_path.result.value != nil
        if Hocon::Impl::ConfigImpl.trace_substitution_enabled
          Hocon::Impl::ConfigImpl.trace(
              "recursively resolving #{resultWithPath} which was the resolution of #{expr} against #{source}",
              depth)
        end

        recursive_resolve_source = Hocon::Impl::ResolveSource.new(
            result_with_path.path_from_root.last, result_with_path.path_from_root)

        if Hocon::Impl::ConfigImpl.trace_substitution_enabled
          Hocon::Impl::ConfigImpl.trace("will recursively resolve against #{recursive_resolve_source}", depth)
        end

        result = new_context.resolve(result_with_path.result.value,
                                     recursive_resolve_source)
        v = result.value
        new_context = result.context
      else
        v = nil
      end
    rescue NotPossibleToResolve => e
      if Hocon::Impl::ConfigImpl.trace_substitution_enabled
        Hocon::Impl::ConfigImpl.trace(
            "not possible to resolve #{expr}, cycle involved: #{e.trace_string}", new_context.depth)
      end
      if @expr.optional
        v = nil
      else
        raise ConfigException.UnresolvedSubstitution(
                  origin,
                  "#{@expr} was part of a cycle of substitutions involving #{e.trace_string}", e)
      end
    end

    if v == nil && !@expr.optional
      if new_context.options.allow_unresolved
        ResolveResult.make(new_context.remove_cycle_marker(self), self)
      else
        raise ConfigException.UnresolvedSubstitution(origin, @expr.to_s)
      end
    else
      ResolveResult.make(new_context.remove_cycle_marker(self), v)
    end

  end
end
