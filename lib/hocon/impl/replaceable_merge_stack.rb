# encoding: utf-8

require_relative '../../hocon/impl'
require_relative '../../hocon/impl/container'
require_relative '../../hocon/config_error'

#
# Implemented by a merge stack (ConfigDelayedMerge, ConfigDelayedMergeObject)
# that replaces itself during substitution resolution in order to implement
# "look backwards only" semantics.
#
module Hocon::Impl::ReplaceableMergeStack
  include Hocon::Impl::Container

  #
  # Make a replacement for this object skipping the given number of elements
  # which are lower in merge priority.
  #
  def make_replacement(context, skipping)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `ReplaceableMergeStack` must implement `make_replacement` (#{self.class})"
  end
end
