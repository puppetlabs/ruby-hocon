# encoding: utf-8

require 'test_utils'

describe "concatenation" do

  it "string concat, no substitutions" do
    conf = TestUtils.parse_config(' a :  true "xyz" 123 foo  ').resolve
    expect(conf.get_string("a")).to eq("true xyz 123 foo")
  end

  it "trivial string concat" do
    conf = TestUtils.parse_config(" a : ${x}foo, x = 1 ").resolve
    expect(conf.get_string("a")).to eq("1foo")
  end

  it "two substitutions and string concat" do
    conf = TestUtils.parse_config(" a : ${x}foo${x}, x = 1 ").resolve
    expect(conf.get_string("a")).to eq("1foo1")
  end

  it "string concat cannot span lines" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigParseError) {
      TestUtils.parse_config(" a : ${x}
        foo, x = 1 ")
    }
    expect(e.message).to include("not be followed")
    expect(e.message).to include("','")
  end

  it "no objects in string concat" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigWrongTypeError) {
      TestUtils.parse_config(" a : abc { x : y } ")
    }
    expect(e.message).to include("Cannot concatenate")
    expect(e.message).to include("abc")
    expect(e.message).to include('{"x":"y"}')
  end

  it "no object concat with nil" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigWrongTypeError) {
      TestUtils.parse_config(" a : null { x : y } ")
    }
    expect(e.message).to include("Cannot concatenate")
    expect(e.message).to include("null")
    expect(e.message).to include('{"x":"y"}')
  end

  it "no arrays in string concat" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigWrongTypeError) {
      TestUtils.parse_config(" a : abc [1, 2] ")
    }
    expect(e.message).to include("Cannot concatenate")
    expect(e.message).to include("abc")
    expect(e.message).to include("[1,2]")
  end

  it "no objects substituted in string concat" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigWrongTypeError) {
      TestUtils.parse_config(" a : abc ${x}, x : { y : z } ").resolve
    }
    expect(e.message).to include("Cannot concatenate")
    expect(e.message).to include("abc")
  end

  it "no arrays substituted in string concat" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigWrongTypeError) {
      TestUtils.parse_config(" a : abc ${x}, x : [1,2] ").resolve
    }
    expect(e.message).to include("Cannot concatenate")
    expect(e.message).to include("abc")
  end

  it "no substitutions in list concat" do
    conf = TestUtils.parse_config(" a :  [1,2] [3,4]  ")
    expect([1, 2, 3, 4]).to eq(conf.get_list("a").unwrapped)
  end

  it "list concat with substitutions" do
    conf = TestUtils.parse_config(" a :  ${x} [3,4] ${y}, x : [1,2], y : [5,6]  ").resolve
    expect([1, 2, 3, 4, 5, 6]).to eq(conf.get_list("a").unwrapped)
  end

  it "list concat self referential" do
    conf = TestUtils.parse_config(" a : [1, 2], a : ${a} [3,4], a : ${a} [5,6]  ").resolve
    expect([1, 2, 3, 4, 5, 6]).to eq(conf.get_list("a").unwrapped)
  end

  it "no substitutions in list concat cannot span lines" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigParseError) {
      TestUtils.parse_config(" a :  [1,2]
                [3,4]  ")
    }
    expect(e.message).to include("expecting")
    expect(e.message).to include("'['")
  end

  it "list concat can span lines inside brackest" do
    conf = TestUtils.parse_config(" a :  [1,2
               ] [3,4]  ")
    expect([1, 2, 3, 4]).to eq(conf.get_list("a").unwrapped)
  end

  it "no substitutions object concat" do
    conf = TestUtils.parse_config(" a : { b : c } { x : y }  ")
    expect({"b" => "c", "x" => "y"}).to eq(conf.get_object("a").unwrapped)
  end

  it "object concat merge order" do
    conf = TestUtils.parse_config(" a : { b : 1 } { b : 2 } { b : 3 } { b : 4 } ")
    expect(4).to eq(conf.get_int("a.b"))
  end

  it "object concat with substitutions" do
    conf = TestUtils.parse_config(" a : ${x} { b : 1 } ${y}, x : { a : 0 }, y : { c : 2 } ").resolve
    expect({"a" => 0, "b" => 1, "c" => 2}).to eq(conf.get_object("a").unwrapped)
  end

  it "object concat self referential" do
    conf = TestUtils.parse_config(" a : { a : 0 }, a : ${a} { b : 1 }, a : ${a} { c : 2 } ").resolve
    expect({"a" => 0, "b" => 1, "c" => 2}).to eq(conf.get_object("a").unwrapped)
  end

  it "object concat self referential override" do
    conf = TestUtils.parse_config(" a : { b : 3 }, a : { b : 2 } ${a} ").resolve
    expect({"b" => 3}).to eq(conf.get_object("a").unwrapped)
  end

  it "no substitutions object concat cannot span lines" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigParseError) {
      TestUtils.parse_config(" a :  { b : c }
                    { x : y }")
    }
    expect(e.message).to include("expecting")
    expect(e.message).to include("'{'")
  end

  it "object concat can span lines inside braces" do
    conf = TestUtils.parse_config(" a :  { b : c
      } { x : y }  ")
    expect({"b" => "c", "x" => "y"}).to eq(conf.get_object("a").unwrapped)
  end

  it "string concat inside array value" do
    conf = TestUtils.parse_config(" a : [ foo bar 10 ] ")
    expect(["foo bar 10"]).to eq(conf.get_string_list("a"))
  end

  it "string non concat inside array value" do
    conf = TestUtils.parse_config(" a : [ foo
                bar
                10 ] ")
    expect(["foo", "bar", "10"]).to eq(conf.get_string_list("a"))
  end

  it "object concat inside array value" do
    conf = TestUtils.parse_config(" a : [ { b : c } { x : y } ] ")
    expect([{"b" => "c", "x" => "y"}]).to eq(conf.get_object_list("a").map { |x| x.unwrapped })
  end

  it "object non concat inside array value" do
    conf = TestUtils.parse_config(" a : [ { b : c }
                { x : y } ] ")
    expect([{"b" => "c"}, {"x" => "y"}]).to eq(conf.get_object_list("a").map { |x| x.unwrapped })
  end

  it "list concat inside array value" do
    conf = TestUtils.parse_config(" a : [ [1, 2] [3, 4] ] ")
    expect([[1,2,3,4]]).to eq(conf.get_list("a").unwrapped)
  end

  it "list non concat inside array value" do
    conf = TestUtils.parse_config(" a : [ [1, 2]
                [3, 4] ] ")
    expect([[1, 2], [3, 4]]).to eq(conf.get_list("a").unwrapped)
  end

  it "string concats are keys" do
    conf = TestUtils.parse_config(' 123 foo : "value" ')
    expect("value").to eq(conf.get_string("123 foo"))
  end

  it "objects are not keys" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigParseError) {
      TestUtils.parse_config('{ { a : 1 } : "value" }')
    }
    expect(e.message).to include("expecting a close")
    expect(e.message).to include("'{'")
  end

  it "arrays are not keys" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigParseError) {
      TestUtils.parse_config('{ [ "a" ] : "value" }')
    }
    expect(e.message).to include("expecting a close")
    expect(e.message).to include("'['")
  end

  it "empty array plus equals" do
    conf = TestUtils.parse_config(' a = [], a += 2 ').resolve
    expect([2]).to eq(conf.get_int_list("a"))
  end

  it "missing array plus equals" do
    conf = TestUtils.parse_config(' a += 2 ').resolve
    expect([2]).to eq(conf.get_int_list("a"))
  end

  it "short array plus equals" do
    conf = TestUtils.parse_config(' a = [1], a += 2 ').resolve
    expect([1, 2]).to eq(conf.get_int_list("a"))
  end

  it "number plus equals" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigWrongTypeError) {
      TestUtils.parse_config(' a = 10, a += 2 ').resolve
    }
    expect(e.message).to include("Cannot concatenate")
    expect(e.message).to include("10")
    expect(e.message).to include("[2]")
  end

  it "string plus equals" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigWrongTypeError) {
      TestUtils.parse_config(' a = abc, a += 2 ').resolve
    }
    expect(e.message).to include("Cannot concatenate")
    expect(e.message).to include("abc")
    expect(e.message).to include("[2]")
  end

  it "objects plus equals" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigWrongTypeError) {
      TestUtils.parse_config(' a = { x : y }, a += 2 ').resolve
    }
    expect(e.message).to include("Cannot concatenate")
    expect(e.message).to include("\"x\":\"y\"")
    expect(e.message).to include("[2]")
  end

  it "plus equals nested path" do
    conf = TestUtils.parse_config(' a.b.c = [1], a.b.c += 2 ').resolve
    expect([1, 2]).to eq(conf.get_int_list("a.b.c"))
  end

  it "plus equals nested objects" do
    conf = TestUtils.parse_config(' a : { b : { c : [1] } }, a : { b : { c += 2 } }').resolve
    expect([1, 2]).to eq(conf.get_int_list("a.b.c"))
  end

  it "plus equals single nested object" do
    conf = TestUtils.parse_config(' a : { b : { c : [1], c += 2 } }').resolve
    expect([1, 2]).to eq(conf.get_int_list("a.b.c"))
  end

  it "substitution plus equals substitution" do
    conf = TestUtils.parse_config(' a = ${x}, a += ${y}, x = [1], y = 2 ').resolve
    expect([1, 2]).to eq(conf.get_int_list("a"))
  end

  it "plus equals multiple times" do
    conf = TestUtils.parse_config(' a += 1, a += 2, a += 3 ').resolve
    expect([1, 2, 3]).to eq(conf.get_int_list("a"))
  end

  it "plus equals multiple times nested" do
    conf = TestUtils.parse_config(' x { a += 1, a += 2, a += 3 } ').resolve
    expect([1, 2, 3]).to eq(conf.get_int_list("x.a"))
  end

  it "plus equals an object multiple times" do
    conf = TestUtils.parse_config(' a += { b: 1 }, a += { b: 2 }, a += { b: 3 } ').resolve
    expect([1, 2, 3]).to eq(conf.get_object_list("a").map { |x| x.to_config.get_int("b")})
  end

  it "plus equals an object multiple times nested" do
    conf = TestUtils.parse_config(' x { a += { b: 1 }, a += { b: 2 }, a += { b: 3 } } ').resolve
    expect([1, 2, 3]).to eq(conf.get_object_list("x.a").map { |x| x.to_config.get_int("b") })
  end

  # We would ideally make this case NOT throw an exception but we need to do some work
  # to get there, see https: // github.com/typesafehub/config/issues/160
  it "plus equals multiple times nested in array" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigParseError) {
      conf = TestUtils.parse_config('x = [ { a += 1, a += 2, a += 3 } ] ').resolve
      expect([1, 2, 3]).to eq(conf.get_object_list("x").to_config.get_int_list("a"))
    }
    expect(e.message).to include("limitation")
  end

  # We would ideally make this case NOT throw an exception but we need to do some work
  # to get there, see https: // github.com/typesafehub/config/issues/160
  it "plus equals multiple times nested in plus equals" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigParseError) {
      conf = TestUtils.parse_config('x += { a += 1, a += 2, a += 3 } ').resolve
      expect([1, 2, 3]).to eq(conf.get_object_list("x").to_config.get_int_list("a"))
    }
    expect(e.message).to include("limitation")
  end

  # from https://github.com/typesafehub/config/issues/177
  it "array concatenation in double nested delayed merge" do
    unresolved = TestUtils.parse_config("d { x = [] }, c : ${d}, c { x += 1, x += 2 }")
    conf = unresolved.resolve
    expect([1,2]).to eq(conf.get_int_list("c.x"))
  end

  # from https://github.com/typesafehub/config/issues/177
  it "array concatenation as part of delayed merge" do
    unresolved = TestUtils.parse_config(" c { x: [], x : ${c.x}[1], x : ${c.x}[2] }")
    conf = unresolved.resolve
    expect([1,2]).to eq(conf.get_int_list("c.x"))
  end

  # from https://github.com/typesafehub/config/issues/177
  it "array concatenation in double nested delayed merge 2" do
    unresolved = TestUtils.parse_config("d { x = [] }, c : ${d}, c { x : ${c.x}[1], x : ${c.x}[2] }")
    conf = unresolved.resolve
    expect([1,2]).to eq(conf.get_int_list("c.x"))
  end

  # from https://github.com/typesafehub/config/issues/177
  it "array concatenation in triple nested delayed merge" do
    unresolved = TestUtils.parse_config("{ r: { d.x=[] }, q: ${r}, q : { d { x = [] }, c : ${q.d}, c { x : ${q.c.x}[1], x : ${q.c.x}[2] } } }")
    conf = unresolved.resolve
    expect([1,2]).to eq(conf.get_int_list("q.c.x"))
  end

  it "concat undefined substitution with string" do
    conf = TestUtils.parse_config("a = foo${?bar}").resolve
    expect("foo").to eq(conf.get_string("a"))
  end

  it "concat defined optional substitution with string" do
    conf = TestUtils.parse_config("bar=bar, a = foo${?bar}").resolve
    expect("foobar").to eq(conf.get_string("a"))
  end

  it "concat defined substitution with array" do
    conf = TestUtils.parse_config("a = [1] ${?bar}").resolve
    expect([1]).to eq(conf.get_int_list("a"))
  end

  it "concat defined optional substitution with array" do
    conf = TestUtils.parse_config("bar=[2], a = [1] ${?bar}").resolve
    expect([1, 2]).to eq(conf.get_int_list("a"))
  end

  it "concat undefined substitution with object" do
    conf = TestUtils.parse_config('a = { x : "foo" } ${?bar}').resolve
    expect('foo').to eq(conf.get_string("a.x"))
  end

  it "concat defined optional substitution with object" do
    conf = TestUtils.parse_config('bar={ y : 42 }, a = { x : "foo" } ${?bar}').resolve
    expect('foo').to eq(conf.get_string("a.x"))
    expect(42).to eq(conf.get_int("a.y"))
  end

  it "concat two undefined substitutions" do
    conf = TestUtils.parse_config("a = ${?foo}${?bar}").resolve
    expect(conf.has_path?("a")).to be_falsey
  end

  it "concat several undefined substitutions" do
    conf = TestUtils.parse_config("a = ${?foo}${?bar}${?baz}${?woooo}").resolve
    expect(conf.has_path?("a")).to be_falsey
  end

  it "concat two undefined substitutions with a space" do
    conf = TestUtils.parse_config("a = ${?foo} ${?bar}").resolve
    expect(conf.get_string("a")).to eq(" ")
  end

  it "concat two defined substitutions with a space" do
    conf = TestUtils.parse_config("foo=abc, bar=def, a = ${foo} ${bar}").resolve
    expect(conf.get_string("a")).to eq("abc def")
  end

  it "concat two undefined substitutions with empty string" do
    conf = TestUtils.parse_config('a = ""${?foo}${?bar}').resolve
    expect(conf.get_string("a")).to eq("")
  end

  it "concat substitutions that are objects with no space" do
    conf = TestUtils.parse_config('foo = { a : 1}, bar = { b : 2 }, x = ${foo}${bar}').resolve
    expect(1).to eq(conf.get_int("x.a"))
    expect(2).to eq(conf.get_int("x.b"))
  end

  # whitespace is insignificant if substitutions don't turn out to be a string
  it "concat substitutions that are objects with space" do
    conf = TestUtils.parse_config('foo = { a : 1}, bar = { b : 2 }, x = ${foo} ${bar}').resolve
    expect(1).to eq(conf.get_int("x.a"))
    expect(2).to eq(conf.get_int("x.b"))
  end

  # whitespace is insignificant if substitutions don't turn out to be a string
  it "concat substitutions that are lists with space" do
    conf = TestUtils.parse_config('foo = [1], bar = [2], x = ${foo} ${bar}').resolve
    expect([1,2]).to eq(conf.get_int_list("x"))
  end

  # but quoted whitespace should be an error
  it "concat substitutions that are objects with quoted space" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigWrongTypeError) {
      conf = TestUtils.parse_config('foo = { a : 1}, bar = { b : 2 }, x = ${foo}"  "${bar}').resolve
    }
  end

  # but quoted whitespace should be an error
  it "concat substitutions that are lists with quoted space" do
    e = TestUtils.intercept(Hocon::ConfigError::ConfigWrongTypeError) {
      conf = TestUtils.parse_config('foo = [1], bar = [2], x = ${foo}"  "${bar}').resolve
    }
  end
end
