# encoding: utf-8

require_relative '../hocon'
require_relative '../hocon/config_error'

#
# Context provided to a {@link ConfigIncluder}; this interface is only useful
# inside a {@code ConfigIncluder} implementation, and is not intended for apps
# to implement.
#
# <p>
# <em>Do not implement this interface</em>; it should only be implemented by
# the config library. Arbitrary implementations will not work because the
# library internals assume a specific concrete implementation. Also, this
# interface is likely to grow new methods over time, so third-party
# implementations will break.
#
module Hocon::ConfigIncludeContext
  #
  # Tries to find a name relative to whatever is doing the including, for
  # example in the same directory as the file doing the including. Returns
  # null if it can't meaningfully create a relative name. The returned
  # parseable may not exist; this function is not required to do any IO, just
  # compute what the name would be.
  #
  # The passed-in filename has to be a complete name (with extension), not
  # just a basename. (Include statements in config files are allowed to give
  # just a basename.)
  #
  # @param filename
  #            the name to make relative to the resource doing the including
  # @return parseable item relative to the resource doing the including, or
  #         null
  #
  def relative_to(filename)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `ConfigIncludeContext` must implement `relative_to` (#{self.class})"
  end

  #
  # Parse options to use (if you use another method to get a
  # {@link ConfigParseable} then use {@link ConfigParseable#options()}
  # instead though).
  #
  # @return the parse options
  #
  def parse_options
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `ConfigIncludeContext` must implement `parse_options` (#{self.class})"
  end
end
