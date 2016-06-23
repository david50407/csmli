struct Csmli::Location
  getter line_number : Int32
  getter column_number : Int32

  def initialize(@line_number, @column_number)
  end
end
