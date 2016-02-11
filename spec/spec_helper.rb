# encoding: utf-8

FIXTURE_DIR = File.join(dir = File.expand_path(File.dirname(__FILE__)), "fixtures")

EXAMPLE1 = { :hash =>
    {"foo" => {
      "bar" => {
          "baz" => 42,
          "abracadabra" => "hi",
          "yahoo" => "yippee",
          "boom" => [1, 2, {"derp" => "duh"}, 4],
          "empty" => [],
          "truthy" => true,
          "falsy" => false
      }}},
    :name => "example1",
}

EXAMPLE2 = { :hash =>
    {"jruby-puppet"=> {
        "jruby-pools" => [{"environment" => "production"}],
        "load-path" => ["/usr/lib/ruby/site_ruby/1.8", "/usr/lib/ruby/site_ruby/1.8"],
        "master-conf-dir" => "/etc/puppet",
        "master-var-dir" => "/var/lib/puppet",
    },
    "webserver" => {"host" => "1.2.3.4"}},
    :name => "example2",
  }

EXAMPLE3 = { :hash =>
                 {"a" => true,
                  "b" => true},
             :name => "example3",
}

EXAMPLE4 = { :hash =>
                 {"kermit" => "frog",
                  "miss" => "piggy",
                  "bert" => "ernie",
                  "janice" => "guitar"},
             :name => "example4",
}

