Gem::Specification.new do |s|
  s.name        = 'hocon'
  s.version     = '0.0.2'
  s.date        = '2014-07-23'
  s.summary     = "HOCON Config Library"
  s.description = "== A port of the Java {Typesafe Config}[https://github.com/typesafehub/config] library to Ruby"
  s.authors     = ["Chris Price", "Wayne Warren"]
  s.email       = 'chris@puppetlabs.com'
  s.files       = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  s.require_paths = ["lib"]
  s.homepage    =
      'https://github.com/cprice404/ruby-hocon'
  s.license       = 'Apache License, v2'

  # Testing dependencies
  s.add_development_dependency 'rspec', '~> 2.14'

end
