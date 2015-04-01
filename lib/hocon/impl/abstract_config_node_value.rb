# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/abstract_config_node'

# This is required if we want
# to be referencing the AbstractConfigNode class in implementation rather than the
# ConfigNode interface, as we can't cast an AbstractConfigNode to an interface
class Hocon::Impl::AbstractConfigNodeValue < Hocon::Impl::AbstractConfigNode

end