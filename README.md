[![Build Status](https://travis-ci.org/puppetlabs/ruby-hocon.png?branch=master)](https://travis-ci.org/puppetlabs/ruby-hocon)

ruby-hocon
==========

This is a port of the [Typesafe Config](https://github.com/typesafehub/config) library to Ruby.

The library provides Ruby support for the [HOCON](https://github.com/typesafehub/config/blob/master/HOCON.md) configuration file format.


At present, it supports supports parsing and modification of existing HOCON/JSON files via the `ConfigFactory`
class and the `ConfigValueFactory` class, and rendering parsed config objects back to a String
([see examples below](#basic-usage)). It also supports the parsing and modification of HOCON/JSON files via
`ConfigDocumentFactory`.

**Note:** While the project is production ready, since not all features in the Typesafe library are supported,
you may still run into some issues. If you find a problem, feel free to open a github issue.

The implementation is intended to be as close to a line-for-line port as the two languages allow,
in hopes of making it fairly easy to port over new changesets from the Java code base over time.

Basic Usage
===========

```sh
gem install hocon
```

To use the simple API, for reading config values:

```rb
require 'hocon'

conf = Hocon.load("myapp.conf")
puts "Here's a setting: #{conf["foo"]["bar"]["baz"]}"
```

To use the ConfigDocument API, if you need both read/write capability for
modifying settings in a config file, or if you want to retain access to
things like comments and line numbers:

```rb
require 'hocon/parser/config_document_factory'
require 'hocon/config_value_factory'

# The below 4 variables will all be ConfigDocument instances
doc = Hocon::Parser::ConfigDocumentFactory.parse_file("myapp.conf")
doc2 = doc.set_value("a.b", "[1, 2, 3, 4, 5]")
doc3 = doc.remove_value("a")
doc4 = doc.set_config_value("a.b", Hocon::ConfigValueFactory.from_any_ref([1, 2, 3, 4, 5]))

doc_has_value = doc.has_value?("a") # returns boolean
orig_doc_text = doc.render # returns string
```

Note that a `ConfigDocument` is used primarily for simple configuration manipulation while preserving
whitespace and comments. As such, it is not powerful as the regular `Config` API, and will not resolve
substitutions.

Testing
=======

```sh
bundle install
bundle exec rspec spec
```

Unsupported Features
====================

This supports many of the same things as the Java library, but there are some notable exceptions.
Unsupported features include:

* Non file includes
* Loading resources from the class path or URLs
* Properties files
* Parsing anything other than files and strings
* Duration and size settings
* Java system properties
