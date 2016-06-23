require "colorize"
require "./parser"

module Csmli
  class Compiler
    def self.run(io : IO)
      new(io).run
    end

    def initialize(io : IO)
      @parser = Parser.new io
      @codegen = Codegen.new
    end

    def run
      ast = @parser.parse
      @codegen.generate ast
    rescue e : ParseException
      STDERR << "Parsing error: ".colorize.bold.red << e.message << "\n"
    rescue e : RuntimeError
      STDERR << "Runtime error: ".colorize.bold.red << e.message << "\n"
    end
  end
end
