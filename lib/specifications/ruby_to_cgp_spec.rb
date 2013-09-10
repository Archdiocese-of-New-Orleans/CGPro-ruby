$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))

require 'communigate/cli'
require 'minitest/spec'
require 'minitest/autorun'
require 'date'

  describe :numerics do    
    it "should convert ruby numerics to CGP numbers" do
      CommuniGate::CliParser.to_cgp(1).must_equal '#1'
      CommuniGate::CliParser.to_cgp(-1).must_equal '#-1'
      CommuniGate::CliParser.to_cgp(-3.14159) == '#-3.14159'
    end
  end
  
  describe "control chars" do
    it "should escape tab and newline" do
      CommuniGate::CliParser.to_cgp("a string with tabs (\t) and newline (\n)").must_equal(
       %q{"a string with tabs (\\t) and newline (\\n)"})
    end

    it "probably it should prune other control chars" do
      CommuniGate::CliParser.to_cgp("a string with vert tab (\v)").must_equal(
       %q{"a string with vert tab ()"})
    end

  end
  
  describe "IP Addresses" do
    it "should convert IPAddr objects to CGP ips" do
      CommuniGate::CliParser.to_cgp(IPAddr.new('192.168.1.1')).must_equal('#I[192.168.1.1]')
      CommuniGate::CliParser.to_cgp([IPAddr.new('10.125.10.40'), 25]).must_equal('#I[10.125.10.40]:25')
    end
  end
  
  describe :strings do
    it "should convert simple strings to unquoted strings" do
      CommuniGate::CliParser.to_cgp("string").must_equal "string"
    end
    
    it "should convert longer strings to quoted strings" do
      CommuniGate::CliParser.to_cgp("longer string").must_equal %q{"longer string"}
    end
    
    it "should convert quoted strings to escaped quoted strings" do
      CommuniGate::CliParser.to_cgp("a \"quoted\" string").must_equal %q{"a \"quoted\" string"}
    end

    it "should escape backslashes" do
      CommuniGate::CliParser.to_cgp("string with backslash (\\)").must_equal %q{"string with backslash (\\\\)"}
    end


  end
  
  describe :time do
    it "should convert DateTime objects to CGP timestamps" do
      t = Time.utc(2002, 10, 20, 07, 45, 30)
      CommuniGate::CliParser.to_cgp(t).must_equal "#T20-10-2002_07:45:30"
    end

    it "should convert Time objects to CGP timestamps" do
      t = DateTime.new(2002, 10, 20, 07, 45, 30)
      CommuniGate::CliParser.to_cgp(t).must_equal "#T20-10-2002_07:45:30"
    end
        
    it "should convert Time objects to CGP dates" do
      t = Date.new(2002, 10, 20)
      CommuniGate::CliParser.to_cgp(t).must_equal "#T20-10-2002"
    end
  
    it "should convert a local DateTime object to CGP timestamp in UTC/GMT" do
      t = DateTime.new(2012, 12, 21, 15, 35, 40, Rational(-3, 24))
      CommuniGate::CliParser.to_cgp(t).must_equal "#T21-12-2012_18:35:40"
    end
    
    it "should convert a local Time object to CGP timestamp in UTC/GMT" do
      t = Time.now
      expected = t.getutc.strftime("#T%d-%m-%Y_%H:%M:%S")
      CommuniGate::CliParser.to_cgp(t).must_equal expected
    end
    
  end
  
  describe :arrays do  
    it "should convert emtpy ruby arrays to empty CGP arrays" do
      CommuniGate::CliParser.to_cgp([]).must_equal("()")
    end

    it "should convert ruby arrays to CGP arrays" do 
      CommuniGate::CliParser.to_cgp([1]).must_equal "(#1)"
      CommuniGate::CliParser.to_cgp([-11, "string", "longer string"]).must_equal '(#-11,string,"longer string")'
    end
  end
  
  describe :hashes do
    it "should convert empty ruby Hashes to CGP dictionaries" do
      CommuniGate::CliParser.to_cgp({}).must_equal "{}"
    end
    
    it "should convert ruby Hashes to CGP dictionaries" do
      input = {:keysymbol => "string", :secondsymbol => "long string"}
      CommuniGate::CliParser.to_cgp(input).must_include "secondsymbol=\"long string\";"
      CommuniGate::CliParser.to_cgp(input).must_include "keysymbol=string;"
    end
    
    it "should convert complex ruby Hashes to CGP dictionaries" do
      complex_hash = {
        :a => "string",
        :b_is_longer => "another string",
        "c" => 1234,
        "d is longer" => ["list", "of", "strings"],
        :e_is_a_hash => { :key => "value" },
        :f => %w(A List Apart),
        :h => Time.utc(2012, 01, 23, 10, 45, 20)
      }
      expected_parts = [
        "a=string;",
        "c=#1234;",
        "\"b_is_longer\"=\"another string\";",
        "\"d is longer\"=(list,of,strings);",
        "f=(A,List,Apart);",
        "\"e_is_a_hash\"={key=value;};",
        "h=#T23-01-2012_10:45:20",
      ]
      result = CommuniGate::CliParser.to_cgp(complex_hash)
      expected_parts.each { |part| result.must_include part }
    end
  end    
