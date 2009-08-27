require 'communigate/data_exception'
require 'communigate/data_block'
require 'ipaddr'
require 'time'

module CommuniGate
  class CliParser
    DATETIME_FORMAT = "#T%d-%m-%Y_%H:%M:%S" 
    DATE_FORMAT = "#T%d-%m-%Y"
    
    def initialize data
      @data = data
      @marker = 0
    end

    def self.to_cgp data
      parser = self.new data
      parser.ruby_to_cg
    end
    
    def self.to_ruby data
      parser = self.new data
      parser.parse_cli
    end

    def parse_cli
      _skip_ws
      c = @data[@marker, 1]
      case c
      when /\(/
        @marker += 1; return _ruby_array
      when /\{/
        @marker += 1; return _ruby_hash
      when /\#/
        if @data[@marker, 3] =~ /\#-*\d/ || @data[@marker, 2] =~ /\#\d/
          @marker += 1
          return _ruby_numeric
        end
        if @data[@marker, 2] =~ /#T/
          @marker += 2
          return _ruby_time
        end
        if @data[@marker, 2] =~ /#I/
          @marker += 2
          return _ruby_string
        end
      else
        return _ruby_string
      end
    end

    def ruby_to_cg(output = @data)
      ret_str = String.new
      if output.class == String && output.to_s.empty?
        return '""'
      elsif output.class == Hash
        ret_str << '{'
        output.each { |key,value| ret_str << ruby_to_cg(key) << '=' << ruby_to_cg(value) << ';' }
        return ret_str + '}'
      elsif output.class == Array
        ret_str << '('
        output.each_index { |idx| ret_str << ',' if idx > 0; ret_str << ruby_to_cg(output[idx]) }
        return ret_str + ')'
      elsif output.class == IPAddr
        return "#I[#{output.to_s}]"
      elsif output.class == Time || output.class == DateTime
        return output.strftime(DATETIME_FORMAT)
      elsif output.class == Date
        return output.strftime(DATE_FORMAT)
      elsif output.is_a?(Numeric)
        return "##{output.to_s}"
      elsif output.is_a?(CommuniGate::DataBlock)
        return "[#{output.datablock}]"
      else
        output = output.to_s if output.class == Symbol
        if output =~ /^[A-Za-z0-9]+$/
          return output
        end
      
        if output =~ /([[:cntrl:]])/
          output.gsub!(/([[:cntrl:]])/m){ |i| "\\" + i[0].to_s.rjust(3,"0"); }
          return %Q{"#{output}"}
        else
          return output.inspect
        end
      end
    end
    
    protected
    def _raise_data_exp(expecting='')
      old_data = @data
      old_marker = @marker
      @data = ''
      @marker = 0
      raise CommuniGate::DataException.new(old_data,old_marker,expecting)
    end
    
    def _skip_ws
      while @data[@marker, 1] =~ /\s/
        @marker += 1
      end
    end

    def _ruby_time
      remain_len = 10 #date w/ no time
      if @data[@marker + remain_len, 1] == '_'
        remain_len = 19
      end
      ret_time = Time.gm(*Time.parse(@data[@marker, remain_len]))
      @marker += remain_len
      return ret_time
    end

    def _ruby_numeric
      _skip_ws
      remain_len = /([-\d\.]+)/.match(@data[@marker, @data.length - @marker])[0].length
      if /\./.match(@data[@marker, remain_len])
        ret_num = @data[@marker, remain_len].to_f
      else
        ret_num = @data[@marker, remain_len].to_i
      end
      @marker += remain_len
      return ret_num
    end


    def _ruby_string
      _skip_ws
      quoted = false
      data_block = false
      c = String.new
      ret_string = String.new
      if /\"/.match(@data[@marker, 1]) 
        quoted = true
        @marker += 1
      elsif /\[/.match(@data[@marker, 1])
        @marker += 1
        rest_string = @data[@marker, @data.length-1];
        the_end = rest_string =~ /\]/;
        ret_string = @data[@marker, the_end].unpack('m')[0]
        @marker += the_end + 1;
        return ret_string
      end

      while @marker < @data.length
        c = @data[@marker, 1]
        if quoted #quoted string
          if c == '\\'
            if @data[@marker, 2] =~ /\\\"/
              c = "\""
              @marker += 1
            elsif @data[@marker + 1, 3] =~ /(?:\\|\d\d\d)/
              @marker += 1
              c = @data[@marker, 3]
              if c =~ /\d\d\d/
                @marker += 2
                c = c.to_i.chr
              else
                c = '\\'+c[0,1]
              end
            end
          elsif c == '"'
            @marker += 1
            _skip_ws
            if @data[@marker, 1] == '"'
              ++@marker
            else
              break
            end
          end
        elsif /[-a-zA-Z0-9\x80-\xff_\.\@\!\#\%\:]/.match(c)
        else
          break
        end
        ret_string << c
        @marker += 1
      end
      return ret_string
    end

    def _ruby_array
      ret_array = Array.new
      while @marker < @data.length
        _skip_ws
        if @data[@marker, 1] == ')'
          @marker += 1
          break
        else
          ret_array.push(parse_cli)
          _skip_ws
          if @data[@marker, 1] == ','
            @marker += 1
          elsif @data[@marker, 1] == ')'
            next
          else
            _raise_data_exp(', or )')
          end
        end	
      end
      return ret_array
    end

    def _ruby_hash
      ret_hash = Hash.new
      while @marker < @data.length
        _skip_ws
        if @data[@marker, 1] == '}'
          @marker += 1
          break
        else
          key = _ruby_string
          _skip_ws
          _raise_data_exp('=') unless @data[@marker, 1] == '='
          @marker += 1
          _skip_ws
          ret_hash[key] = parse_cli
          _raise_data_exp(';') unless @data[@marker, 1] == ';'
          @marker += 1
        end
      end
      return ret_hash
    end
  end
end