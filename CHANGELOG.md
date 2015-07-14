## 0.9.3

This is a bugfix release.

* Fixed a bug wherein inserting an array or a hash into a ConfigDocument would cause
  "# hardcoded value" comments to be generated before every entry in the hash/array.

## 0.9.2

This is a bugfix release

* Fixed a bug wherein attempting to insert a complex value (such as an array or a hash) into an empty
  ConfigDocument would cause an undefined method error.

## 0.9.1

This is a bugfix release.
* Fixed a bug wherein ugly configurations were being generated due to the addition of new objects when a setting
  is set at a path that does not currently exist in the configuration. Previously, these new objects were being
  added as single-line objects. They will now be added as multi-line objects if the parent object is a multi-line
  object or is an empty root object.

## 0.9.0

This is a promotion of the 0.1.0 release with one small bug fix:
* Fixed bug wherein using the `set_config_value` method with some parsed values would cause a failure due to surrounding whitespace

## 0.1.0

This is a feature release containing a large number of changes and improvements

* Added support for concatenation
* Added support for substitutions
* Added support for file includes. Other types of includes are not supported
* Added the new ConfigDocument API that was recently implemented in the upstream Java library
* Improved JSON support
* Fixed a large number of small bugs related to various pieces of implementation
