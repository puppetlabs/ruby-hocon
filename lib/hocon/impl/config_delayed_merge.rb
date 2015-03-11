require 'hocon/impl'
require 'hocon/impl/replaceable_merge_stack'
require 'hocon/impl/config_delayed_merge_object'

class Hocon::Impl::ConfigDelayedMerge < Hocon::Impl::AbstractConfigValue
  include Hocon::Impl::Unmergeable
  include Hocon::Impl::ReplaceableMergeStack

  def initialize(origin, stack)
    super(origin)
    @stack = stack

    if stack.empty?
      raise Hocon::ConfigError::ConfigBugOrBrokenError.new("creating empty delayed merge value", nil)
    end

    stack.each do |v|
      if v.is_a?(Hocon::Impl::ConfigDelayedMerge) || v.is_a?(Hocon::Impl::ConfigDelayedMergeObject)
        error_message = "placed nested DelayedMerge in a ConfigDelayedMerge, should have consolidated stack"
        raise Hocon::ConfigError::ConfigBugOrBrokenError.new(error_message, nil)
      end
    end
  end

  attr_reader :stack


  def value_type
    error_message = "called value_type() on value with unresolved substitutions, need to Config#resolve() first, see API docs"
    raise Hocon::ConfigError::ConfigNotResolvedError.new(error_message, nil)
  end

  def unwrapped
    error_message = "called unwrapped() on value with unresolved substitutions, need to Config#resolve() first, see API docs"
    raise Hocon::ConfigError::ConfigNotResolvedError.new(error_message, nil)
  end

  def resolve_status
    Hocon::Impl::ResolveStatus::UNRESOLVED
  end

  def can_equal(other)
    other.is_a? Hocon::Impl::ConfigDelayedMerge
  end

  def ==(other)
    # note that "origin" is deliberately NOT part of equality
    if other.is_a? Hocon::Impl::ConfigDelayedMerge
      can_equal(other) && (@stack == other.stack || @stack.equal?(other.stack))
    else
      false
    end
  end

  def hash
    # note that "origin" is deliberately NOT part of equality
    @stack.hash
  end
end
