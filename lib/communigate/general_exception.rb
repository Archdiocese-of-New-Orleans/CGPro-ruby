module CommuniGate
  class GeneralException < RuntimeError
    attr :message
    def initialize(errstr)
      @message = errstr
    end

    def to_s
      @message
    end
  end
end