require "./parser"

module Csmli
  class Compiler
    def self.run(io : IO)
      new(io).run
    end

    def initialize(io : IO)
      @parser = Parser.new io
    end

    def run
      @parser.parse
    end
  end
end
