$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'hocon/version'

Gem::Specification.new do |s|
  s.name        = 'hocon'
  s.version     = Hocon::Version::STRING
  s.date        = '2016-10-12'
  s.summary     = "HOCON Config Library"
  s.description = "== A port of the Java {Typesafe Config}[https://github.com/typesafehub/config] library to Ruby"
  s.authors     = ["Chris Price", "Wayne Warren", "Preben Ingvaldsen", "Joe Pinsonault", "Kevin Corcoran", "Jane Lu"]
  s.email       = 'chris@puppetlabs.com'
  s.files       = Dir["{lib}/**/*.rb", "spec/**/*" , "bin/*", "LICENSE", "*.md"]
  s.require_paths = ["lib"]
  s.executables   = ['hocon']
  s.homepage      = 'https://github.com/puppetlabs/ruby-hocon'
  s.license       = 'Apache License, v2'
  s.required_ruby_version = '>=1.9.0'

  # Testing dependencies
  s.add_development_dependency 'bundler', '~> 1.5'
  s.add_development_dependency 'rspec', '~> 2.14'
end
