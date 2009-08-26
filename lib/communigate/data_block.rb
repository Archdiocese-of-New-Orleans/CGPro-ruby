module CommuniGate
  class DataBlock
    attr :datablock
    def initialize(str)
      @datablock = str.to_a.pack('m').gsub("\n", '')
    end
  end
end