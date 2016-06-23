class Csmli::Codegen
  @variables : Hash(String, Int32 | Bool | Function)
  @stack : Array(Hash(String, Int32 | Bool | Function))

  def initialize
    @variables = {} of String => Int32 | Bool | Function
    @stack = [] of Hash(String, Int32 | Bool | Function)
  end

  def generate(ast : ASTNode)
    visit ast
  end

  def visit(node : Nop)
  end

  def visit(node : Statements)
    node.each do |n|
      visit n
    end
  end

  def visit(node : Define)
    name = node.variable_name
    exp = node.exp

    value = visit(exp)
    raise_type(exp) if value.nil?
    @variables[name] = value
    nil
  end

  def visit(node : Print)
    exp = node.exp

    value = visit(exp)
    if node.type == :bool
      raise_type(exp, :Bool) if value.is_a? Int32
      puts value ? "#t": "#f"
    else # if node.type == :num
      raise_type(exp, :Number) if value.is_a? Bool
      puts value
    end
    nil
  end

  def visit(node : Number) : Int32
    node.value
  end

  def visit(node : Boolean) : Bool
    node.value
  end

  def visit(node : Variable) : Int32 | Bool | Function
    raise "Undefined variable: `#{node.name}`", node if @variables[node.name]?.nil?
    @variables[node.name]
  end

  def visit(node : Operation) : Int32 | Bool
    args = node.args
    case node.op
    when :+
      value = 0
      args.each do |arg|
        v = visit(arg).as? Int32
        raise_type(arg, :Number) if v.nil?
        value += v
      end
      value
    when :-
      val = { visit(args[0]).as?(Int32), visit(args[1]).as?(Int32) }
      raise_type(args[0], :Number) if val[0].nil?
      raise_type(args[1], :Number) if val[1].nil?
      val[0].not_nil! - val[1].not_nil!
    when :*
      value = 1
      node.args.each do |arg|
        v = visit(arg)
        raise_type arg, :Number unless v.is_a?(Int32)
        value *= v
      end
      value
    when :/
      val = { visit(args[0]).as?(Int32), visit(args[1]).as?(Int32) }
      raise_type(args[0], :Number) if val[0].nil?
      raise_type(args[1], :Number) if val[1].nil?
      val[0].not_nil! / val[1].not_nil! #/
    when :mod
      val = { visit(args[0]).as?(Int32), visit(args[1]).as?(Int32) }
      raise_type(args[0], :Number) if val[0].nil?
      raise_type(args[1], :Number) if val[1].nil?
      val[0].not_nil! % val[1].not_nil!
    when :>
      val = { visit(args[0]).as?(Int32), visit(args[1]).as?(Int32) }
      raise_type(args[0], :Number) if val[0].nil?
      raise_type(args[1], :Number) if val[1].nil?
      val[0].not_nil! > val[1].not_nil!
    when :<
      val = { visit(args[0]).as?(Int32), visit(args[1]).as?(Int32) }
      raise_type(args[0], :Number) if val[0].nil?
      raise_type(args[1], :Number) if val[1].nil?
      val[0].not_nil! < val[1].not_nil!
    when :"="
      first = node.args.shift
      first_value = visit(first)
      raise_type first unless first_value.is_a?(Int32) || first_value.is_a?(Bool)
      node.args.each do |arg|
        v = visit(arg)
        raise_type arg unless v.class == first_value.class
        return false if v != first_value
      end
      true
    when :and
      node.args.each do |arg|
        v = visit(arg)
        raise_type arg, :Bool unless v.is_a?(Bool)
        return false if !v
      end
      true
    when :or
      node.args.each do |arg|
        v = visit(arg)
        raise_type arg, :Bool unless v.is_a?(Bool)
        return true if v
      end
      false
    when :not
      v = visit(args.first)
      raise_type args.first, :Bool unless v.is_a?(Bool)
      !v
    else
      raise "Never reach here", node
    end
  end

  def visit(node : If) : Bool | Int32 | Function | Nil
    test_value = visit(node.test_exp)
    raise_type node.test_exp, :Bool unless test_value.is_a? Bool
    test_value ? visit(node.then_exp) : visit(node.else_exp)
  end

  def visit(node : Function) : Function
    node
  end

  def visit(node : Call) : Bool | Int32 | Function | Nil
  end

  private def raise_type(node, expected_type : Symbol? = nil)
    raise "Unexpected type", node if expected_type.nil?
    raise "Unexpected type, expecting `#{expected_type}`", node
  end

  private def raise(msg, node)
    ::raise RuntimeError.new(msg, node.location)
  end
end
