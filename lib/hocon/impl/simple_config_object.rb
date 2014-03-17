require 'hocon/impl'
require 'hocon/impl/simple_config_origin'
require 'hocon/impl/abstract_config_object'
require 'hocon/impl/resolve_status'
require 'set'

class Hocon::Impl::SimpleConfigObject < Hocon::Impl::AbstractConfigObject
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

  def empty?
    @value.empty?
  end

end