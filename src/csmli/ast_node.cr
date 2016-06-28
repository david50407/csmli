module Csmli
  abstract class ASTNode
    property! location : Location?
    property end_location : Location?

    def at(@location : Location?)
      self
    end

    def at_end(@end_location : Location?)
      self
    end

    def clone
      clone = clone_without_location
      clone.location = location
      clone.end_location = end_location
      clone
    end

    def nop?
      false
    end
  end

  class Nop < ASTNode
    def nop?
      true
    end

    def clone_without_location
      Nop.new
    end

    def_equals_and_hash
  end

  # A container for one or many statements.
  class Statements < ASTNode
    def self.from(obj : Array)
      if obj.size == 0
        return Nop.new
      elsif obj.size == 1
        return obj.first
      else
        return Statements.new(obj)
      end
    end

    def self.from(node : ASTNode)
      node
    end

    def initialize(@statements = [] of ASTNode)
    end

    delegate empty?, to: @statements
    delegate last, to: @statements
    delegate each, to: @statements

    def end_location
      @end_location || last.try &.end_location
    end

    def clone_without_location
      Statements.new @statements.clone
    end

    def_equals_and_hash statements
  end

  class Define < ASTNode
    property variable_name : String
    property! exp : Expression?

    def initialize(@variable_name : String)
    end

    def clone_without_location
      clone = Define.new variable_name
      clone.exp = exp
      clone
    end

    def_equals_and_hash variable_name, exp
  end

  class Print < ASTNode
    property type : Symbol
    property! exp : Expression?

    def initialize(@type : Symbol)
    end

    def clone_without_location
      clone = Print.new type
      clone.exp = exp
      clone
    end

    def_equals_and_hash type, exp
  end

  abstract class Expression < ASTNode
  end

  class Number < Expression
    property value : Int32

    def initialize(@value : Int32)
    end

    def clone_without_location
      Number.new value
    end

    def_equals_and_hash value
  end

  class Boolean < Expression
    property value : Bool

    def initialize(@value : Bool)
    end

    def clone_without_location
      Boolean.new value
    end

    def_equals_and_hash
  end

  class Operation < Expression
    property op : Symbol
    property args : Array(Expression)

    def initialize(@op : Symbol)
      @args = [] of Expression
    end

    def clone_without_location
      clone = Operation.new op
      clone.args = args
      clone
    end

    def_equals_and_hash op, args
  end

  class Variable < Expression
    property name : String

    def initialize(@name : String)
    end

    def clone_without_location
      Variable.new name
    end

    def_equals_and_hash name
  end

  class Function < Expression
    property args : Array(String)
    property defs : Array(Define)
    property! exp : Expression?
    property! closure : Array(Hash(String, Bool | Int32 | Function))?

    def initialize
      @args = [] of String
      @defs = [] of Define
    end

    def clone_without_location
      clone = Function.new
      clone.args = args
      clone.defs = defs
      clone.exp = exp
      clone
    end

    def_equals_and_hash args, defs, exp
  end

  class If < Expression
    property! test_exp : Expression?
    property! then_exp : Expression?
    property! else_exp : Expression?

    def clone_without_location
      clone = If.new
      clone.test_exp = test_exp
      clone.then_exp = then_exp
      clone.else_exp = else_exp
      clone
    end

    def_equals_and_hash test_exp, then_exp, else_exp
  end

  class Call < Expression
    property func : String | Function
    property params : Array(Expression)

    def initialize(@func : String | Function)
      @params = [] of Expression
    end

    def clone_without_location
      clone = Call.new func
      clone.params = params
      clone
    end

    def_equals_and_hash func, params
  end
end
