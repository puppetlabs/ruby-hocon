require 'typesafe/config/impl'
require 'typesafe/config/impl/abstract_config_value'
require 'typesafe/config/impl/simple_config'
require 'typesafe/config/config_object'
require 'typesafe/config/config_value_type'
require 'typesafe/config/impl/resolve_status'
require 'typesafe/config/impl/simple_config_origin'

class Typesafe::Config::Impl::AbstractConfigObject < Typesafe::Config::Impl::AbstractConfigValue
  include Typesafe::Config::ConfigObject

  def initialize(origin)
    super(origin)
    @config = Typesafe::Config::Impl::SimpleConfig.new(self)
  end

  def to_config
    @config
  end

  def to_fallback_value
    self
  end

  def value_type
    Typesafe::Config::ConfigValueType::OBJECT
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

      if (v.is_a?(Typesafe::Config::Impl::AbstractConfigObject)) &&
          (v.resolve_status == Typesafe::Config::Impl::ResolveStatus::RESOLVED) &&
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

    Typesafe::Config::Impl::SimpleConfigOrigin.merge_origins(origins)
  end
end