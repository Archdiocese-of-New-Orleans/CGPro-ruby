require File.dirname(__FILE__) + '/spec_helper'
require 'date'

context "CommuniGate CLI library from CGP to Ruby" do
  describe :numerics do    
    it "should convert CGP integer to Ruby numeric" do
      CommuniGate::CliParser.to_ruby('#-3.14159') == -3.14159
    end
  end

  describe "control chars" do
    it "should convert to CGP escaped" do
      CommuniGate::CliParser.to_ruby(%q{"a\009string\009with\009tabs\000"}).
        should == "a\tstring\twith\ttabs\0"
    end
  end

  describe :strings do
    it "should convert simple strings to unquoted strings" do
      CommuniGate::CliParser.to_ruby("string").should == "string"
    end
  
    it "should convert longer strings to quoted strings" do
      CommuniGate::CliParser.to_ruby(%q{"longer string"}).should == 
        "longer string"
    end
  
    it "should convert quoted strings to escaped quoted strings" do
      CommuniGate::CliParser.to_ruby(%q{"a \"quoted\" string"}).should ==
        "a \"quoted\" string"
    end
  end

  describe :time do
    it "should convert DateTime objects to CGP timestamps" do
      t = Time.utc(2002, 10, 20, 07, 45, 30)
      CommuniGate::CliParser.to_ruby("#T20-10-2002_07:45:30").should == t
    end
  
    it "should convert Time objects to CGP dates" do
      t = Time.utc(2002, 10, 20)
      CommuniGate::CliParser.to_ruby("#T20-10-2002").should == t
    end
  end

  describe :arrays do  
    it "should convert emtpy ruby arrays to empty CGP arrays" do
      CommuniGate::CliParser.to_ruby("()").should == []
    end

    it "should convert ruby arrays to CGP arrays" do 
      CommuniGate::CliParser.to_ruby("(#1)").should == [1]
      CommuniGate::CliParser.to_ruby('(#-11, string, "longer string")') ==
        [-11, "string", "longer string"]
    end
  end

  describe :hashes do
    it "should convert empty ruby Hashes to CGP dictionaries" do
      CommuniGate::CliParser.to_ruby("{}").should == {}
    end
  
    it "should convert ruby Hashes to CGP dictionaries" do
      output = {"keysymbol" => "string", "secondsymbol" => "long string"}
      input = "{keysymbol=string;secondsymbol=\"long string\";}"
      CommuniGate::CliParser.to_ruby(input).should == output
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
      CommuniGate::CliParser.to_ruby(complex_hash).should == expected
    end
  end
end