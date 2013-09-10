$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))

require 'communigate/cli'
require 'minitest/spec'
require 'minitest/autorun'
require 'date'

describe :numerics do    
  it "should convert CGP integer to Ruby numeric" do
    CommuniGate::CliParser.to_ruby('#-3.14159').must_equal -3.14159
    CommuniGate::CliParser.to_ruby('#12354').must_equal 12354
  end
end

describe "control chars" do
  it "should convert to CGP escaped" do
    CommuniGate::CliParser.to_ruby(%q{"a\009string\009with\009tabs\000"}).
      must_equal "a\tstring\twith\ttabs\0"
  end
end

describe "IP Addresses" do
  it "should convert CGP ips to IPAddr objects" do
    CommuniGate::CliParser.to_ruby('#I[192.168.1.1]').
      must_equal IPAddr.new('192.168.1.1')
    CommuniGate::CliParser.to_ruby('#I[172.16.104.10]:587').must_equal([IPAddr.new('172.16.104.10'), 587])
  end
end

describe :strings do
  it "should convert simple strings to unquoted strings" do
    CommuniGate::CliParser.to_ruby("string").must_equal "string"
  end

  it "should convert longer strings to quoted strings" do
    CommuniGate::CliParser.to_ruby(%q{"longer string"}).must_equal "longer string"
  end

  it "should convert quoted strings to escaped quoted strings" do
    CommuniGate::CliParser.to_ruby(%q{"a \"quoted\" string"}).must_equal("a \"quoted\" string")
    CommuniGate::CliParser.to_ruby(%q{"a \"quoted\" string"}).must_equal(%q{a "quoted" string})
  end
end

describe :time do
  it "should convert DateTime objects to CGP timestamps" do
    t = Time.utc(2002, 10, 20, 07, 45, 30)
    CommuniGate::CliParser.to_ruby("#T20-10-2002_07:45:30").must_equal t
  end

  it "should convert Time objects to CGP dates" do
    t = Time.utc(2002, 10, 20)
    CommuniGate::CliParser.to_ruby("#T20-10-2002").must_equal t
  end
end

describe :arrays do  
  it "should convert emtpy ruby arrays to empty CGP arrays" do
    CommuniGate::CliParser.to_ruby("()").must_equal []
  end

  it "should convert ruby arrays to CGP arrays" do 
    CommuniGate::CliParser.to_ruby("(#1)").must_equal [1]
    CommuniGate::CliParser.to_ruby('(#-11, string, "longer string")').
      must_equal [-11, "string", "longer string"]
    CommuniGate::CliParser.to_ruby('(three, simple, strings)').
      must_equal %w(three simple strings)
  end
end

describe :hashes do
  it "should convert empty ruby Hashes to CGP dictionaries" do
    CommuniGate::CliParser.to_ruby("{}").must_equal({})
  end

  it "should convert ruby Hashes to CGP dictionaries" do
    output = {"keysymbol" => "string", "secondsymbol" => "long string"}
    input = "{keysymbol=string;secondsymbol=\"long string\";}"
    CommuniGate::CliParser.to_ruby(input).must_equal output
  end

  it "should convert complex ruby Hashes to CGP dictionaries" do
    expected = {
      "a" => "string",
      "b_is_longer" => "another string",
      "c" => 1234,
      "d is longer" => ["list", "of", "strings"],
      "e_is_a_hash" => { "key" => "value" },
      "f" => %w(A List Apart),
      "h" => Time.utc(2012, 01, 23, 10, 45, 20)
    }
    complex_hash = "{" +
      "a=string;" +
      "\"b_is_longer\"=\"another string\";" +
      "c=#1234;" +
      "\"d is longer\"=(list,of,strings);" +
      "\"e_is_a_hash\"={key=value;};" +
      "f=(A,List,Apart);" +
      "h=#T23-01-2012_10:45:20;" +
      "}"
    CommuniGate::CliParser.to_ruby(complex_hash).must_equal expected
  end
end
