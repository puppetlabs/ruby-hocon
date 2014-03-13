require 'typesafe/config/impl'
require 'stringio'
require 'typesafe/config/config_render_options'
require 'typesafe/config/config_object'
require 'typesafe/config/impl/resolve_status'
require 'typesafe/config/impl/unmergeable'
require 'typesafe/config/impl/abstract_config_object'
require 'typesafe/config/impl/config_impl_util'

##
## Trying very hard to avoid a parent reference in config values; when you have
## a tree like this, the availability of parent() tends to result in a lot of
## improperly-factored and non-modular code. Please don't add parent().
##
class Typesafe::Config::Impl::AbstractConfigValue
  ConfigImplUtil = Typesafe::Config::Impl::ConfigImplUtil

  def initialize(origin)
    @origin = origin
  end

  attr_reader :origin

  def resolve_status
    Typesafe::Config::Impl::ResolveStatus::RESOLVED
  end

  # this is virtualized rather than a field because only some subclasses
  # really need to store the boolean, and they may be able to pack it
  # with another boolean to save space.
  def ignores_fallbacks?
    # if we are not resolved, then somewhere in this value there's
    # a substitution that may need to look at the fallbacks.
    resolve_status == Typesafe::Config::Impl::ResolveStatus::RESOLVED
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
      if other.is_a?(Typesafe::Config::Impl::Unmergeable)
        merged_with_the_unmergeable(other)
      elsif other.is_a?(Typesafe::Config::Impl::AbstractConfigObject)
        merged_with_object(other)
      else
        merged_with_non_object(other)
      end
    end
  end

  def to_s
    sb = StringIO.new
    render_to_sb(sb, 0, true, nil, Typesafe::Config::ConfigRenderOptions.concise)
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
        if self.is_a?(Typesafe::Config::ConfigObject)
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

  def render(options = Typesafe::Config::ConfigRenderOptions.defaults)
    sb = StringIO.new
    render_to_sb(sb, 0, true, nil, options)
    # We take a substring that ends at sb.pos, because we've been decrementing
    # sb.pos at various points in the code as a means to remove characters from
    # the end of the StringIO
    sb.string[0, sb.pos]
  end

end