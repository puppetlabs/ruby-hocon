# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/simple_config_origin'
require 'hocon/impl/abstract_config_object'
require 'hocon/impl/resolve_status'
require 'hocon/impl/resolve_result'
require 'hocon/config_error'
require 'set'
require 'forwardable'


class Hocon::Impl::SimpleConfigObject < Hocon::Impl::AbstractConfigObject
  extend Forwardable

  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
  ResolveStatus = Hocon::Impl::ResolveStatus
  ResolveResult = Hocon::Impl::ResolveResult
  SimpleConfigOrigin = Hocon::Impl::SimpleConfigOrigin

  def self.empty_missing(base_origin)
    self.new(
        Hocon::Impl::SimpleConfigOrigin.new_simple("#{base_origin.description} (not found)"),
        {})
  end

  def initialize(origin, value,
                  status = Hocon::Impl::ResolveStatus.from_values(value.values),
                  ignores_fallbacks = false)
    super(origin)
    if value.nil?
      raise ConfigBugError, "creating config object with null map"
    end
    @value = value
    @resolved = (status == Hocon::Impl::ResolveStatus::RESOLVED)
    @ignores_fallbacks = ignores_fallbacks

    # Kind of an expensive debug check. Comment out?
    if status != Hocon::Impl::ResolveStatus.from_values(value.values)
      raise ConfigBugError, "Wrong resolved status on #{self}"
    end
  end

  attr_reader :value
  # To support accessing ConfigObjects like a hash
  def_delegators :@value, :[], :has_key?, :has_value?, :empty?, :size, :keys, :values, :each, :map


  def new_copy_with_status(new_status, new_origin, new_ignores_fallbacks = nil)
    Hocon::Impl::SimpleConfigObject.new(new_origin,
              @value, new_status, new_ignores_fallbacks)
  end

  def ignores_fallbacks?
    @ignores_fallbacks
  end

  def unwrapped
    @value.merge(@value) { |k,v| v.unwrapped }
  end

  def merged_with_object(abstract_fallback)
    require_not_ignoring_fallbacks

    unless abstract_fallback.is_a?(Hocon::Impl::SimpleConfigObject)
      raise ConfigBugError, "should not be reached (merging non-SimpleConfigObject)"
    end

    fallback = abstract_fallback
    changed = false
    all_resolved = true
    merged = {}
    all_keys = key_set.union(fallback.key_set)
    all_keys.each do |key|
      first = @value[key]
      second = fallback.value[key]
      kept =
          if first.nil?
            second
          elsif second.nil?
            first
          else
            first.with_fallback(second)
          end
      merged[key] = kept

      if first != kept
        changed = true
      end

      if kept.resolve_status == Hocon::Impl::ResolveStatus::UNRESOLVED
        all_resolved = false
      end
    end

    new_resolve_status = Hocon::Impl::ResolveStatus.from_boolean(all_resolved)
    new_ignores_fallbacks = fallback.ignores_fallbacks?

    if changed
      Hocon::Impl::SimpleConfigObject.new(merge_origins([self, fallback]),
                             merged, new_resolve_status,
                             new_ignores_fallbacks)
    elsif (new_resolve_status != resolve_status) || (new_ignores_fallbacks != ignores_fallbacks?)
      newCopy(new_resolve_status, origin, new_ignores_fallbacks)
    else
      self
    end
  end

  def render_value_to_sb(sb, indent_size, at_root, options)
    if empty?
      sb << "{}"
    else
      outer_braces = options.json? || !at_root

      inner_indent =
        if outer_braces
          sb << "{"
          if options.formatted?
            sb << "\n"
          end
          indent_size + 1
        else
          indent_size
        end

      separator_count = 0
      key_set.each do |k|
        v = @value[k]

        if options.origin_comments?
          indent(sb, inner_indent, options)
          sb << "# "
          sb << v.origin.description
          sb << "\n"
        end
        if options.comments?
          v.origin.comments.each do |comment|
            indent(sb, inner_indent, options)
            sb << "#"
            if !comment.start_with?(" ")
              sb << " "
            end
            sb << comment
            sb << "\n"
          end
        end
        indent(sb, inner_indent, options)
        v.render_to_sb(sb, inner_indent, false, k.to_s, options)

        if options.formatted?
          if options.json?
            sb << ","
            separator_count = 2
          else
            separator_count = 1
          end
          sb << "\n"
        else
          sb << ","
          separator_count = 1
        end
      end
      # chop last commas/newlines
      # couldn't figure out a better way to chop characters off of the end of
      # the StringIO.  This relies on making sure that, prior to returning the
      # final string, we take a substring that ends at sb.pos.
      sb.pos = sb.pos - separator_count

      if outer_braces
        if options.formatted?
          sb << "\n" # put a newline back
          if outer_braces
            indent(sb, indent_size, options)
          end
        end
        sb << "}"
      end
    end
    if at_root && options.formatted?
      sb << "\n"
    end
  end


  def key_set
    Set.new(@value.keys)
  end

  def self.map_hash(m)
    # the keys have to be sorted, otherwise we could be equal
    # to another map but have a different hashcode.
    keys = m.keys.sort

    value_hash = 0

    keys.each do |key|
      value_hash += m[key].hash
    end

    41 * (41 + keys.hash) + value_hash
  end

  def self.map_equals(a, b)
    # This array comparison works if there are no duplicates, which
    # the hash keys won't have
    sets_equal = lambda { |x, y| (x.size == y.size) && (x & y == x) }

    if a == b
      return true
    end

    if not sets_equal.call(a.keys, b.keys)
      return false
    end

    a.keys.each do |key|
      if a[key] != b[key]
        return false
      end
    end

    true
  end

  def can_equal(other)
    other.is_a? Hocon::Impl::AbstractConfigObject
  end

  def ==(other)
    # note that "origin" is deliberately NOT part of equality.
    # neither are other "extras" like ignoresFallbacks or resolve status.
    if other.is_a? Hocon::Impl::AbstractConfigObject
      # optimization to avoid unwrapped() for two ConfigObject,
      # which is what AbstractConfigValue does.
      can_equal(other) && self.class.map_equals(@value, other.value)
    else
      false
    end
  end

  def hash
    self.class.map_hash(@value)
  end

  def empty?
    @value.empty?
  end

  def attempt_peek_with_partial_resolve(key)
    @value[key]
  end

  def without_path(path)
    key = path.first
    remainder = path.remainder
    v = @value[key]

    if (not v.nil?) && (not remainder.nil?) && v.is_a?(Hocon::Impl::AbstractConfigObject)
      v = v.without_path(remainder)
      updated = @value.clone
      updated[key] = v
      Hocon::Impl::SimpleConfigObject.new(origin,
                                          updated,
                                          ResolveStatus.from_values(updated.values), @ignores_fallbacks)
    elsif (not remainder.nil?) || v.nil?
      return self
    else
      smaller = Hash.new
      @value.each do |old_key, old_value|
        unless old_key == key
          smaller[old_key] = old_value
        end
      end
      Hocon::Impl::SimpleConfigObject.new(origin,
                                          smaller,
                                          ResolveStatus.from_values(smaller.values), @ignores_fallbacks)
    end
  end

  def with_value(path, v)
    key = path.first
    remainder = path.remainder

    if remainder.nil?
      with_value_impl(key, v)
    else
      child = @value[key]
      if (not child.nil?) && child.is_a?(Hocon::Impl::AbstractConfigObject)
        return with_value_impl(key, child.with_value(remainder, v))
      else
        subtree = v.at_path(
            SimpleConfigOrigin.new_simple("with_value(#{remainder.render})"), remainder)
        with_value_impl(key, subtree.root)
      end
    end
  end

  def with_value_impl(key, v)
    if v.nil?
      raise ConfigBugOrBrokenError.new("Trying to store null ConfigValue in a ConfigObject")
    end

    new_map = Hash.new
    if @value.empty?
      new_map[key] = v
    else
      new_map = @value.clone
      new_map[key] = v
    end
    self.class.new(origin, new_map, ResolveStatus.from_values(new_map.values), @ignores_fallbacks)
  end

  def resolve_substitutions(context, source)
    if resolve_status == ResolveStatus::RESOLVED
      return ResolveResult.make(context, self)
    end

    source_with_parent = source.push_parent(self)

    begin
      modifier = ResolveModifier.new(context, source_with_parent)

      value = modify_may_throw(modifier)
      ResolveResult.make(modifier.context, value)

    rescue NotPossibleToResolve => e
      raise e
    rescue RuntimeError => e
      raise e
    rescue Exception => e
      raise ConfigBugOrBrokenError.new("unexpected exception", e)
    end
  end

  def self.empty(origin = nil)
    if origin.nil?
      empty(SimpleConfigOrigin.new_simple("empty config"))
    else
      SimpleConfigObject.new(origin, {})
    end
  end
end
