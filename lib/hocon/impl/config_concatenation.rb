require 'hocon/impl'
require 'hocon/impl/abstract_config_value'
require 'hocon/impl/abstract_config_object'
require 'hocon/impl/simple_config_list'
require 'hocon/config_object'
require 'hocon/impl/unmergeable'
require 'hocon/impl/simple_config_origin'
require 'hocon/impl/config_string'

class Hocon::Impl::ConfigConcatenation < Hocon::Impl::AbstractConfigValue
  include Hocon::Impl::Unmergeable

  SimpleConfigList = Hocon::Impl::SimpleConfigList
  ConfigObject = Hocon::ConfigObject
  Unmergeable = Hocon::Impl::Unmergeable
  SimpleConfigOrigin = Hocon::Impl::SimpleConfigOrigin

  #
  # Add left and right, or their merger, to builder
  #
  def self.join(builder, orig_right)
    left = builder[builder.size - 1]
    right = orig_right

    # check for an object which can be converted to a list
    # (this will be an object with numeric keys, like foo.0, foo.1)
    if (left.is_a?(ConfigObject)) && (right.is_a?(SimpleConfigList))
      left = DefaultTransformer.transform(left, ConfigValueType::LIST)
    elsif (left.is_a?(SimpleConfigList)) && (right.is_a?(ConfigObject))
      right = DefaultTransformer.transform(right, ConfigValueType::LIST)
    end

    # Since this depends on the type of two instances, I couldn't think
    # of much alternative to an instanceof chain. Visitors are sometimes
    # used for multiple dispatch but seems like overkill.
    joined = nil
    if (left.is_a?(ConfigObject)) && (right.is_a?(ConfigObject))
      joined = right.with_fallback(left)
    elsif (left.is_a?(SimpleConfigList)) && (right.is_a?(SimpleConfigList))
      joined = left.concatenate(right)
    elsif (left.is_a?(Hocon::Impl::ConfigConcatenation)) ||
        (right.is_a?(Hocon::Impl::ConfigConcatenation))
      raise ConfigBugError, "unflattened ConfigConcatenation"
    elsif (left.is_a?(Unmergeable)) || (right.is_a?(Unmergeable))
      # leave joined=null, cannot join
    else
      # handle primitive type or primitive type mixed with object or list
      s1 = left.transform_to_string
      s2 = right.transform_to_string
      if s1.nil? || s2.nil?
        raise ConfigWrongTypeError.new(left.origin,
                "Cannot concatenate object or list with a non-object-or-list, #{left} " +
                    "and #{right} are not compatible")
      else
        joined_origin = SimpleConfigOrigin.merge_origins([left.origin, right.origin])
        joined = Hocon::Impl::ConfigString.new(joined_origin, s1 + s2)
      end
    end

    if joined.nil?
      builder.push(right)
    else
      builder.pop
      builder.push(joined)
    end
  end

  def self.consolidate(pieces)
    if pieces.length < 2
      pieces
    else
      flattened = []
      pieces.each do |v|
        if v.is_a?(Hocon::Impl::ConfigConcatenation)
          flattened.concat(v.pieces)
        else
          flattened.push(v)
        end
      end

      consolidated = []
      flattened.each do |v|
        if consolidated.empty?
          consolidated.push(v)
        else
          join(consolidated, v)
        end
      end

      consolidated
    end
  end

  def self.concatenate(pieces)
    consolidated = consolidate(pieces)
    if consolidated.empty?
      nil
    elsif consolidated.length == 1
      consolidated[0]
    else
      merged_origin = SimpleConfigOrigin.merge_origins(consolidated)
      Hocon::Impl::ConfigConcatenation.new(merged_origin, consolidated)
    end
  end


  def initialize(origin, pieces)
    super(origin)
    @pieces = pieces

    if pieces.size < 2
      raise ConfigBugError, "Created concatenation with less than 2 items: #{self}"
    end

    had_unmergeable = false
    pieces.each do |p|
      if p.is_a?(Hocon::Impl::ConfigConcatenation)
        raise ConfigBugError, "ConfigConcatenation should never be nested: #{self}"
      end
      if p.is_a?(Unmergeable)
        had_unmergeable = true
      end
    end

    unless had_unmergeable
      raise ConfigBugError, "Created concatenation without an unmergeable in it: #{self}"
    end
  end

  def ignores_fallbacks?
    # we can never ignore fallbacks because if a child ConfigReference
    # is self-referential we have to look lower in the merge stack
    # for its value.
    false
  end
end