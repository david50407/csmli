module Csmli
  class ParseException < Exception
    getter line_number : Int32
    getter column_number : Int32

    def initialize(msg, @line_number, @column_number)
      super "#{msg} at #{@line_number}:#{@column_number}"
    end
  end

  class RuntimeError < Exception
    getter line_number : Int32
    getter column_number : Int32

    def initialize(msg, empty : Nil)
      @line_number = 0
      @column_number = 0
      super msg
    end

    def initialize(msg, location : Location)
      @line_number = location.line_number
      @column_number = location.column_number
      super "#{msg} at #{@line_number}:#{@column_number}"
    end
  end
end
