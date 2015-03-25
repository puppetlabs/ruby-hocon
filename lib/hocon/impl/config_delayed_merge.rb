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

  def render_to_sb(sb, indent, at_root, at_key, options)
    self.class.render_value_to_sb_from_stack(stack, sb, indent, at_root, at_key, options)
  end

  # static method also used by ConfigDelayedMergeObject.
  def self.render_value_to_sb_from_stack(stack, sb, indent, at_root, at_key, options)
    comment_merge = options.comments

    if comment_merge
      sb << "# unresolved merge of #{stack.size} values follows (\n"
      if at_key.nil?
        self.indent(sb, indent, options)
        sb << "# this unresolved merge will not be parseable because it's at the root of the object\n"
        self.indent(sb, indent, options)
        sb << "# the HOCON format has no way to list multiple root objects in a single file\n"
      end
    end

    reversed = stack.reverse

    i = 0

    reversed.each do |v|
      if comment_merge
        self.indent(sb, indent, options)
        if !at_key.nil?
          rendered_key = Hocon::Impl::ConfigImplUtil.render_json_string(at_key)
          sb << "#     unmerged value #{i} for key #{rendered_key}"
        else
          sb << "#     unmerged value #{i} from "
        end
        i += 1

        sb << v.origin.description
        sb << "\n"

        v.origin.comments.each do |comment|
          self.indent(sb, indent, options)
          sb << "# "
          sb << comment
          sb << "\n"
        end
      end
      self.indent(sb, indent, options)

      if !at_key.nil?
        sb << Hocon::Impl::ConfigImplUtil.render_json_string(at_key)
        if options.formatted
          sb << " : "
        else
          sb << ":"
        end
      end

      v.render_value_to_sb(sb, indent, at_root, options)
      sb << ","

      if options.formatted
        sb.append "\n"
      end
    end

    # chop comma or newline
    sb.string = sb.string[0...-1]
    if options.formatted
      sb.string = sb.string[0...-1]
      sb << "\n"
    end

    if comment_merge
      self.indent(sb, indent, options)
      sb << "# ) end of unresolved merge\n"
    end
  end
end
