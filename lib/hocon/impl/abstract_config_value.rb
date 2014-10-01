require 'hocon/impl'
require 'stringio'
require 'hocon/config_render_options'
require 'hocon/config_object'
require 'hocon/impl/resolve_status'
require 'hocon/impl/unmergeable'
require 'hocon/impl/abstract_config_object'
require 'hocon/impl/config_impl_util'

##
## Trying very hard to avoid a parent reference in config values; when you have
## a tree like this, the availability of parent() tends to result in a lot of
## improperly-factored and non-modular code. Please don't add parent().
##
class Hocon::Impl::AbstractConfigValue
  ConfigImplUtil = Hocon::Impl::ConfigImplUtil

  def initialize(origin)
    @origin = origin
  end

  attr_reader :origin

  def resolve_status
    Hocon::Impl::ResolveStatus::RESOLVED
  end

  # this is virtualized rather than a field because only some subclasses
  # really need to store the boolean, and they may be able to pack it
  # with another boolean to save space.
  def ignores_fallbacks?
    # if we are not resolved, then somewhere in this value there's
    # a substitution that may need to look at the fallbacks.
    resolve_status == Hocon::Impl::ResolveStatus::RESOLVED
  end

  # the withFallback() implementation is supposed to avoid calling
  # mergedWith* if we're ignoring fallbacks.
  def require_not_ignoring_fallbacks
    if ignores_fallbacks?
      raise ConfigBugError, "method should not have been called with ignoresFallbacks=true #{self.class.name}"
    end
  end

  def with_origin(origin)
    if @origin == origin
      self
    else
      new_copy(origin)
    end
  end

  def with_fallback(mergeable)
    if ignores_fallbacks?
      self
    else
      other = mergeable.to_fallback_value
      if other.is_a?(Hocon::Impl::Unmergeable)
        merged_with_the_unmergeable(other)
      elsif other.is_a?(Hocon::Impl::AbstractConfigObject)
        merged_with_object(other)
      else
        merged_with_non_object(other)
      end
    end
  end

  def to_s
    sb = StringIO.new
    render_to_sb(sb, 0, true, nil, Hocon::ConfigRenderOptions.concise)
    "#{self.class.name}(#{sb.string})"
  end

  def indent(sb, indent_size, options)
    if options.formatted?
      remaining = indent_size
      while remaining > 0
        sb << "    "
        remaining -= 1
      end
    end
  end

  def render_to_sb(sb, indent, at_root, at_key, options)
    if !at_key.nil?
      rendered_key =
          if options.json?
            ConfigImplUtil.render_json_string(at_key)
          else
            ConfigImplUtil.render_string_unquoted_if_possible(at_key)
          end

      sb << rendered_key

      if options.json?
        if options.formatted?
          sb << " : "
        else
          sb << ":"
        end
      else
        # in non-JSON we can omit the colon or equals before an object
        if self.is_a?(Hocon::ConfigObject)
          if options.formatted?
            sb << ' '
          end
        else
          sb << "="
        end
      end
    end
    render_value_to_sb(sb, indent, at_root, options)
  end

  # to be overridden by subclasses
  def render_value_to_sb(sb, indent, at_root, options)
    u = unwrapped
    sb << u.to_s
  end

  def render(options = Hocon::ConfigRenderOptions.defaults)
    sb = StringIO.new
    render_to_sb(sb, 0, true, nil, options)
    # We take a substring that ends at sb.pos, because we've been decrementing
    # sb.pos at various points in the code as a means to remove characters from
    # the end of the StringIO
    sb.string[0, sb.pos]
  end

  def at_key(origin, key)
    m = {key=>self}
    Hocon::Impl::SimpleConfigObject.new(origin, m).to_config
  end

  def at_path(origin, path)
    parent = path.parent
    result = at_key(origin, path.last)
    while not parent.nil? do
      key = parent.last
      result = result.at_key(origin, key)
      parent = parent.parent
    end
    result
  end

end