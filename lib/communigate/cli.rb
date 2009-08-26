require 'socket'
require 'ipaddr'
require 'digest/md5'
require 'communigate/data_block'
require 'communigate/general_exception'
require 'communigate/data_exception'

module CommuniGate
  class Cli

    SEND_PASS     	= '300'
    OK            	= '200'
    OK_INLINE     	= '201'
    PASSWORD      	= '300'
    UNKNOWN_USER  	= '500'
    GENERAL_ERROR 	= '501'

    def initialize(params)
      params.keys.each {|k| params[k.to_sym] = params[k]}
      raise CommuniGate::GeneralException.new("No hostname supplied") unless params[:hostname]
      raise CommuniGate::GeneralException.new("No username supplied") unless params[:username]
      raise CommuniGate::GeneralException.new("No password supplied") unless params[:password]
      params[:port]  ||= 106
      params[:debug] ||= false
      @_params = params
      @data = String.new
      @marker = 0
      _connect
      _login
      ObjectSpace.define_finalizer(self, CommuniGate.create_finalizer(@connection))
    end

    #disconnect issues the "quit" command and closes the connection to the Communigate server.
    #This is only needed if you want to explicitly disconnect since there is a finalizer that handles clean disconnect after object destruction.
    def disconnect
      _logout
      @connection.close
    end

    def _reconnect
      @connection.close
      _connect
      _login
    end

    def _send(command)
      STDERR.puts "#{command}" if @_params[:debug]
      @connection.print("#{command}\n")
      _parse_response
    end

    def _login

      if (@_banner_code != nil)
        hash = Digest::MD5.hexdigest(@_banner_code + @_params[:password])
        _send("APOP #{@_params[:username]} #{hash}")
      else
        _send("USER #{@_params[:username]}")
        _send("PASS #{@_params[:password]}")
      end
      @_connected = Time.new
    end

    def _logout
      _send("quit")
    end

    def self.create_finalizer(connection)
      proc { |id| connection.print("quit\n"); connection.close; }
    end

    def _connect
      begin
        @connection = TCPSocket.new(@_params[:hostname],@_params[:port])
      rescue Errno::ECONNREFUSED => e
        raise CommuniGate::GeneralException.new("Unable to connect to host #{@_params[:hostname]} on port #{@_params[:port]}: #{e.message}")
      end
      @connection.sync = true
      response = @connection.gets
      match = response.match(/(\<.*\@*\>)/)
      if (match.size > 0)
        @_banner_code = match.captures[0]
      end
    end

    def _gather_data
      lastline = false
      while (true)
        line = @connection.gets
        lastline = true if /\r$/.match(line) #data ends w/ ctrl-lf		
        @data << line.strip
        break if lastline 
      end
    end


    def _parse_output
      _skip_ws
      c = @data[@marker,1]
      case c
      when /\(/
        @marker+=1; return _ruby_array
      when /\{/
        @marker+=1; return _ruby_hash
      when /\#/
        if @data[@marker,3] =~ /\#-*\d/ || @data[@marker,2] =~ /\#\d/ then @marker+=1; return _ruby_numeric end
        if @data[@marker,2] =~ /#T/ then @marker+=2; return _ruby_time end
        if @data[@marker,2] =~ /#I/ then @marker+=2; return _ruby_string end
      else
        return _ruby_string
      end
    end

    def _skip_ws
      while /\s/.match(@data[@marker,1])
        @marker+=1
      end
    end

    def _ruby_time
      remain_len = 10 #date w/ no time
      if @data[@marker+remain_len,1] == '_'
        remain_len = 19
      end
      ret_time = Time.gm(*Time.parse(@data[@marker,remain_len]))
      @marker+=remain_len
      return ret_time
    end

    def _ruby_numeric
      _skip_ws
      remain_len = /([-\d\.]+)/.match(@data[@marker,@data.length-@marker])[0].length
      if /\./.match(@data[@marker,remain_len])
        ret_num = @data[@marker,remain_len].to_f
      else
        ret_num = @data[@marker,remain_len].to_i
      end
      @marker+=remain_len
      return ret_num
    end


    def _ruby_string
      _skip_ws
      quoted = false
      data_block = false
      c = String.new
      ret_string = String.new
      if /\"/.match(@data[@marker,1]) 
        quoted = true
        @marker+=1
      elsif /\[/.match(@data[@marker,1])
        @marker+=1
        rest_string = @data[@marker,@data.length-1];
        the_end = rest_string =~ /\]/;
        ret_string = @data[@marker,the_end].unpack('m')[0]
        @marker += the_end + 1;
        return ret_string
      end

      while @marker < @data.length
        c = @data[@marker,1]
        if quoted #quoted string
          if c == '\\'
            if /(?:\"|\\|\d\d\d)/.match(@data[@marker,3])
              @marker+=1
              c = @data[@marker,3]
              if /\d\d\d/.match(c)
                @marker+=2
                c=c.to_i.chr
              elsif c == "\""
                c += "\\\""
              else
                c='\\'+c[0,1]
              end
            end
          elsif c == '"'
            @marker+=1
            _skip_ws
            if @data[@marker,1] == '"'
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
        @marker+=1
      end
      return ret_string
    end

    def _ruby_array
      ret_array = Array.new
      while @marker < @data.length
        _skip_ws
        if @data[@marker,1] == ')'
          @marker+=1
          break
        else
          ret_array.push(_parse_output)
          _skip_ws
          if @data[@marker,1] == ','
            @marker+=1
          elsif @data[@marker,1] == ')'
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
        if @data[@marker,1] == '}'
          @marker+=1
          break
        else
          key = _ruby_string
          _skip_ws
          _raise_data_exp('=') unless @data[@marker,1] == '='
          @marker+=1
          _skip_ws
          ret_hash[key] = _parse_output
          _raise_data_exp(';') unless @data[@marker,1] == ';'
          @marker+=1
        end
      end

      return ret_hash
    end

    def self._ruby_to_cg(output)
      ret_str = String.new
      if output.class == String && output.to_s.empty?
        return '""'
      elsif output.class == Hash
        ret_str << '{'
        output.each { |key,value| ret_str << _ruby_to_cg(key) << '=' << _ruby_to_cg(value) << ';' }
        return ret_str + '}'
      elsif output.class == Array
        ret_str << '('
        output.each_index { |idx| ret_str << ',' if idx > 0; ret_str << _ruby_to_cg(output[idx]) }
        return ret_str + ')'
      elsif output.class == IPAddr
        return "#I[#{output.to_s}]"
      elsif output.class == Time || output.class == DateTime
        return output.strftime("#T%d-%m-%Y_%H:%M:%S")
      elsif output.class == Date
        return output.strftime("#T%d-%m-%Y")
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

    def _raise_data_exp(expecting='')
      old_data = @data
      old_marker = @marker
      @data = ''
      @marker = 0
      raise CommuniGate::DataException.new(old_data,old_marker,expecting)
    end

    def _parse_response
      response = @connection.gets || String.new
      response.strip!
      #   	puts response
      unless response.empty?
        @_data_waiting = false
        rmatch = /(\d+) (.*)/.match(response)
        case rmatch[1]
        when SEND_PASS
          return true
        when OK 
          _gather_data if rmatch[2].strip == "data follow"
          @_data_waiting = true
          return true
        when OK_INLINE
          return true 
        end
      end
      raise CommuniGate::GeneralException.new("The CG server returned an error: '#{response}'")  
    end 

    #method missing is used to call all api methods. If an unsupported method is called, a CgGeneralException to be raised. 
    #Additionally, a CgDataException will be raised if there is an error in parsing data returned from the Communigate server.
    def method_missing(called,*args)
      send_str = called.to_s.gsub("_", "")
      args.each { |arg| send_str += " #{CommuniGate._ruby_to_cg(arg)}" } unless args.empty?
      _reconnect if Time.new > (@_connected + 295) #timeout is 5 mins so this gives us 5 secs of error room
      _send(send_str)
      return _parse_output if @_data_waiting
    end
  end
end
