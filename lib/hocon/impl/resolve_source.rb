require 'hocon'
require 'hocon/config_error'
require 'hocon/impl'

class Hocon::Impl::ResolveSource

  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError

  def initialize(root, path_from_root = nil)
    @root = root
    @path_from_root = path_from_root
  end

  def push_parent(parent)
    unless parent
      raise ConfigBugOrBrokenError.new("can't push null parent")
    end

    if Hocon::Impl::ConfigImpl.trace_substitution_enabled
      Hocon::Impl::ConfigImpl.trace("pushing parent #{parent} ==root #{(parent == root)} onto #{self}")
    end

    if @path_from_root == nil
      if parent.equal?(@root)
        return ResolveSource.new(@root, Node.new(parent))
      else
        if Hocon::Impl::ConfigImpl.trace_substitution_enabled
          # this hasDescendant check is super-expensive so it's a
          # trace message rather than an assertion
          if @root.has_descendant(parent)
            Hocon::Impl::ConfigImpl.trace(
                "***** BUG ***** tried to push parent #{parent} without having a path to it in #{self}")
          end
        end
        # ignore parents if we aren't proceeding from the
        # root
        return self
      end
    else
      parent_parent = @path_from_root.head
      if Hocon::Impl::ConfigImpl.trace_substitution_enabled
        # this hasDescendant check is super-expensive so it's a
        # trace message rather than an assertion
        if parent_parent != nil && !parent_parent.has_descendant(parent)
          Hocon::Impl::ConfigImpl.trace(
              "***** BUG ***** trying to push non-child of #{parent_parent}, non-child was #{parent}")
        end
      end

      ResolveSource.new(@root, @path_from_root.prepend(parent))
    end
  end

  class Node

    attr_reader :next_node, :value

    def initialize(value, next_node = nil)
      @value = value
      @next_node = next_node
    end

    def prepend(value)
      Node.new(value, self)
    end

    def head
      @value
    end

    def tail
      @next_node
    end

    def last
      i = self
      while i.next_node != nil
        i = i.next_node
      end
      i.value
    end

    def reverse
      if @next_node == nil
        self
      else
        reversed = Nod
        e.new(@value)
        i = @next_node
        while i != nil
          reversed = reversed.prepend(i.value)
          i = i.next_node
        end
        reversed
      end
    end

    def to_s
      sb = ""
      sb << "["
      to_append_value = self.reverse
      while to_append_value != nil
        sb << to_append_value.value.to_s
        if to_append_value.next != nil
          sb << " <= "
        end
        to_append_value = to_append_value.next
      end
      sb << "]"
      sb
    end
  end
end
