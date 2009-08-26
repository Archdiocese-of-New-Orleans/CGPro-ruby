require 'socket'
require 'digest/md5'
require 'communigate/cli_parser'
require 'communigate/general_exception'

module CommuniGate
  class Cli
    SEND_PASS     	= '300'
    OK            	= '200'
    OK_INLINE     	= '201'
    PASSWORD      	= '300'
    UNKNOWN_USER  	= '500'
    GENERAL_ERROR 	= '501'

    def initialize(params)
      params.keys.each { |k| params[k.to_sym] = params[k] }
      raise CommuniGate::GeneralException.new("No hostname supplied") \
        unless params[:hostname]
      raise CommuniGate::GeneralException.new("No username supplied") \
        unless params[:username]
      raise CommuniGate::GeneralException.new("No password supplied") \
        unless params[:password]
      params[:port]  ||= 106
      params[:debug] ||= false
      @_params = params
      @data = String.new
      @marker = 0
      _connect
      _login
      ObjectSpace.define_finalizer(self,
        CommuniGate::Cli.create_finalizer(@connection))
    end

    # Disconnect issues the "quit" command and closes the connection to the
    # Communigate server.
    # This is only needed if you want to explicitly disconnect since there is a
    # finalizer that handles clean disconnect after object destruction.
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
        @connection = TCPSocket.new(@_params[:hostname], @_params[:port])
      rescue Errno::ECONNREFUSED => e
        raise CommuniGate::GeneralException.new("Unable to connect to host " +
          "#{@_params[:hostname]} on port #{@_params[:port]}: #{e.message}")
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
      while true
        line = @connection.gets
        lastline = true if /\r$/.match(line) # data ends w/ ctrl-lf
        @data << line.strip
        break if lastline 
      end
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

    def _parse_output
      CommuniGate::CliParser.to_ruby @data
    end

    #method missing is used to call all api methods. If an unsupported method is called, a CgGeneralException to be raised. 
    #Additionally, a CgDataException will be raised if there is an error in parsing data returned from the Communigate server.
    def method_missing(called,*args)
      send_str = called.to_s.gsub("_", "")
      args.each { |arg| send_str += " #{CommuniGate::CliParser.to_cgp(arg)}"} unless args.empty?
      _reconnect if Time.new > (@_connected + 295) #timeout is 5 mins so this gives us 5 secs of error room
      _send(send_str)
      return _parse_output if @_data_waiting
    end
  end
end
