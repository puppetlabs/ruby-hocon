require 'hocon/impl'
require 'hocon/impl/resolve_status'
require 'hocon/config_value_type'
require 'hocon/impl/abstract_config_object'

class Hocon::Impl::SimpleConfigList < Hocon::Impl::AbstractConfigValue
  ResolveStatus = Hocon::Impl::ResolveStatus

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
