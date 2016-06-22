class Csmli::Token
  property type : Symbol
  property number_value : Int32
  property value : String
  property line_number : Int32
  property column_number : Int32

  def initialize
    @type = :EOF
    @line_number = 0
    @column_number = 0
    @number_value = 0
    @value = ""
  end

  def to_s(io)
    io << "<Token type=`"
    @type.to_s io
    io << "`"
    case @type
    when :number
      io << " value=`"
      @number_value.to_s io
      io << "`"
    when :ident
      io << " value=`"
      io << @value
      io << "`"
    end
    io << ">"
  end
end
