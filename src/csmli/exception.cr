module Csmli
  class ParseException < Exception
    getter line_number : Int32
    getter column_number : Int32

    def initialize(msg, @line_number, @column_number)
      super "#{msg} at #{@line_number}:#{@column_number}"
    end
  end
end
