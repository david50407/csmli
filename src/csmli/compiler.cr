require "colorize"
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
    rescue e : ParseException
      STDERR << "Parsing error: ".colorize.bold.red << e.message << "\n"
    end
  end
end
