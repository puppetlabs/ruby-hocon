[![Build Status](https://travis-ci.org/puppetlabs/ruby-hocon.png?branch=master)](https://travis-ci.org/puppetlabs/ruby-hocon)

ruby-hocon
==========

This is a port of the [Typesafe Config](https://github.com/typesafehub/config) library to Ruby.

The library provides Ruby support for the [HOCON](https://github.com/typesafehub/config/blob/master/HOCON.md) configuration file format.

At present, the only features it supports are explicit parsing of config files (.conf/HOCON, .json) via `ConfigFactory.parse_file`, and rendering a parsed config object back to a String.  Testing is minimal and not all data types are supported yet.  It also does not yet support `include` or interpolated settings.
PLEASE NOTE that as a result this project is in a very experimental state, and in some cases may not work properly, so
please be wary when using it. If you find a problem, feel free to open a github issue.

The implementation is intended to be as close to a line-for-line port as the two languages allow, in hopes of making it fairly easy to port over new changesets from the Java code base over time.

Basic Usage
===========

```sh
gem install hocon
```


```rb
require 'hocon/config_factory'

conf = Hocon::ConfigFactory.parse_file("myapp.conf")
conf_map = conf.root.unwrapped
```

Testing
=======

```sh
bundle install
bundle exec rspec spec
```
