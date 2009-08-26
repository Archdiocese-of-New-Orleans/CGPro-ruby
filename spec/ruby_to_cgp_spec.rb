require File.dirname(__FILE__) + '/spec_helper'

context "CommuniGate CLI library from Ruby to CGP" do
  describe :numerics do    
    it "should convert ruby numerics to CGP numbers" do
      CommuniGate::CliParser.to_cgp(1).should == '#1'
      CommuniGate::CliParser.to_cgp(-1).should == '#-1'
      CommuniGate::CliParser.to_cgp(-3.14159) == '#-3.14159'
    end
  end
  
  describe "control chars" do
    it "should convert to CGP escaped" do
      CommuniGate::CliParser.to_cgp("a\tstring\twith\ttabs\0").should == 
        %q{"a\009string\009with\009tabs\000"}
    end
  end
  
  describe "IP Addresses" do
    it "should convert IPAddr objects to CGP ips" do
      CommuniGate::CliParser.to_cgp(IPAddr.new('192.168.1.1')).should ==
        '#I[192.168.1.1]'
    end
  end
  
  describe :strings do
    it "should convert simple strings to unquoted strings" do
      CommuniGate::CliParser.to_cgp("string").should == "string"
    end
    
    it "should convert longer strings to quoted strings" do
      CommuniGate::CliParser.to_cgp("longer string").should ==
        %q{"longer string"}
    end
    
    it "should convert quoted strings to escaped quoted strings" do
      CommuniGate::CliParser.to_cgp("a \"quoted\" string").should == 
        %q{"a \"quoted\" string"}
    end
  end
  
  describe :time do
    it "should convert Time objects to CGP timestamps" do
      t = DateTime.new(2002, 10, 20, 07, 45, 30)
      CommuniGate::CliParser.to_cgp(t).should == "#T20-10-2002_07:45:30"
    end
    
    it "should convert DateTime objects to CGP timestamps" do
      t = Time.local(2002, 10, 20, 07, 45, 30)
      CommuniGate::CliParser.to_cgp(t).should == "#T20-10-2002_07:45:30"
    end
    
    it "should convert Time objects to CGP dates" do
      t = Date.new(2002, 10, 20)
      CommuniGate::CliParser.to_cgp(t).should == "#T20-10-2002"
    end
    
  end
  
  describe :arrays do  
    it "should convert emtpy ruby arrays to empty CGP arrays" do
      CommuniGate::CliParser.to_cgp([]).should == "()"
    end

    it "should convert ruby arrays to CGP arrays" do 
      CommuniGate::CliParser.to_cgp([1]).should == "(#1)"
      CommuniGate::CliParser.to_cgp([-11, "string", "longer string"]) ==
        '(#-11, string, "longer string")'
    end
  end
  
  describe :hashes do
    it "should convert empty ruby Hashes to CGP dictionaries" do
      CommuniGate::CliParser.to_cgp({}).should == "{}"
    end
    
    it "should convert ruby Hashes to CGP dictionaries" do
      input = {:keysymbol => "string", :secondsymbol => "long string"}
      CommuniGate::CliParser.to_cgp(input).should include "secondsymbol=\"long string\";"
      CommuniGate::CliParser.to_cgp(input).should include "keysymbol=string;"
    end
    
    it "should convert complex ruby Hashes to CGP dictionaries" do
      complex_hash = {
        :a => "string",
        :b_is_longer => "another string",
        "c" => 1234,
        "d is longer" => ["list", "of", "strings"],
        :e_is_a_hash => { :key => "value" },
        :f => %w(A List Apart),
        :h => Time.local(2012, 01, 23, 10, 45, 20)
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
      expected_parts.each { |part| result.should include part }
    end
  end    
end

