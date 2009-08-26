module CommuniGate
  class DataException < RuntimeError
    attr :buffer
    attr :occurred_at
    attr :expecting
    attr :message
    
    def initialize(buffer,occurred_at,expecting='')
      @message = "Error parsing data returned from the server. The error occurred near '#{buffer[occurred_at,10]}' while expecting #{expecting}.\nThe data returned by the server follows:\n\n#{buffer}\n"
      @buffer = buffer
      @occurred_at = occurred_at
      @expecting = expecting
    end

    def to_s
      @message
    end
  end
end