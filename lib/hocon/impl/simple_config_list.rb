# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/resolve_status'
require 'hocon/config_value_type'
require 'hocon/config_error'
require 'hocon/impl/abstract_config_object'

class Hocon::Impl::SimpleConfigList < Hocon::Impl::AbstractConfigValue
  ResolveStatus = Hocon::Impl::ResolveStatus
  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError

  def initialize(origin, value, status = ResolveStatus.from_values(value))
    super(origin)
    @value = value
    @resolved = (status == ResolveStatus::RESOLVED)

    # kind of an expensive debug check (makes this constructor pointless)
    if status != ResolveStatus.from_values(value)
      raise ConfigBugError, "SimpleConfigList created with wrong resolve status: #{self}"
    end
  end

  def value_type
    Hocon::ConfigValueType::LIST
  end

  def unwrapped
    @value.map { |v| v.unwrapped }
  end

  def modify_may_throw(modifier, new_resolve_status)
    # lazy-create for optimization
    changed = nil
    i = 0
    @value.each { |v|
      modified = modifier.modify_child_may_throw(nil, v)

      # lazy-create the new list if required
      if changed == nil && !modified.equal?(v)
        changed = []
        j = 0
        while j < i
          changed << @value[j]
          j += 1
        end
      end

      # once the new list is created, all elements
      # have to go in it.if modifyChild returned
      # null, we drop that element.
      if changed != nil && modified != nil
        changed << modified
      end

      i += 1
    }

    if changed != nil
      if new_resolve_status != nil
        SimpleConfigList.new(origin, changed, new_resolve_status)
      else
        SimpleConfigList.new(origin, changed)
      end
    else
      self
    end
  end

  class ResolveModifier
    attr_reader :context, :source
    def initialize(context, source)
      @context = context
      @source = source
    end
  end

  def resolve_substitutions(context, source)
    if @resolved
      return ResolveResult.make(context, self)
    end

    if context.is_restricted_to_child
      # if a list restricts to a child path, then it has no child paths,
      # so nothing to do.
      ResolveResult.make(context, self)
    else
      begin
        modifier = ResolveModifier.new(context, source.push_parent(self))
        value = modify_may_throw(modifier, context.options.allow_unresolved ? nil : ResolveStatus::RESOLVED)
        ResolveResult.make(modifier.context, value)
      rescue NotPossibleToResolve => e
        raise e
      rescue RuntimeError => e
        raise e
      rescue Exception => e
        raise ConfigBugOrBrokenError("unexpected exception", e)
      end
    end
  end


  def render_value_to_sb(sb, indent_size, at_root, options)
    if @value.empty?
      sb << "[]"
    else
      sb << "["
      if options.formatted?
        sb << "\n"
      end
      @value.each do |v|
        if options.origin_comments?
          indent(sb, indent_size + 1, options)
          sb << "# "
          sb << v.origin.description
          sb << "\n"
        end
        if options.comments?
          v.origin.comments.each do |comment|
            sb << "# "
            sb << comment
            sb << "\n"
          end
        end
        indent(sb, indent_size + 1, options)

        v.render_value_to_sb(sb, indent_size + 1, at_root, options)
        sb << ","
        if options.formatted?
          sb << "\n"
        end
      end

      # couldn't figure out a better way to chop characters off of the end of
      # the StringIO.  This relies on making sure that, prior to returning the
      # final string, we take a substring that ends at sb.pos.
      sb.pos = sb.pos - 1 # chop or newline
      if options.formatted?
        sb.pos = sb.pos - 1 # also chop comma
        sb << "\n"
        indent(sb, indent_size, options)
      end
      sb << "]"
    end
  end

  def new_copy(origin)
    Hocon::Impl::SimpleConfigList.new(origin, @value)
  end
end
