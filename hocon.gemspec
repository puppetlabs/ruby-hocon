Gem::Specification.new do |s|
  s.name        = 'hocon'
  s.version     = '0.9.3'
  s.date        = '2015-07-14'
  s.summary     = "HOCON Config Library"
  s.description = "== A port of the Java {Typesafe Config}[https://github.com/typesafehub/config] library to Ruby"
  s.authors     = ["Chris Price", "Wayne Warren", "Preben Ingvaldsen", "Joe Pinsonault", "Kevin Corcoran"]
  s.email       = 'chris@puppetlabs.com'
  s.files       = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  s.require_paths = ["lib"]
  s.homepage      = 'https://github.com/puppetlabs/ruby-hocon'
  s.license       = 'Apache License, v2'
  s.required_ruby_version = '>=1.9.0'

  # Testing dependencies
  s.add_development_dependency 'bundler', '~> 1.5'
  s.add_development_dependency 'rspec', '~> 2.14'
end
