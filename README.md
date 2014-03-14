ruby-typesafe-config
==========

This is a port of the [Typesafe Config](https://github.com/typesafehub/config) library to Ruby.

At present, the only features it supports are explicit parsing of config files (.conf/HOCON, .json, .properties) via `ConfigFactory.parse_file`, and rendering a parsed config object back to a String.  Testing is minimal and not all data types are supported yet.  It also does not yet support `include` or interpolated settings.

The implementation is intended to be as close to a line-for-line port as the two languages allow, in hopes of making it fairly easy to port over new changesets from the Java code base over time.

Basic Usage
===========

```rb
require 'typesafe/config/config_factory'

conf = Typesafe::Config::ConfigFactory.parse_file("myapp.conf")
conf_map = conf.root.unwrapped
