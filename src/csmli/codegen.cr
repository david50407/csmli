class Csmli::Codegen
  @stack : Array(Hash(String, Int32 | Bool | Function))

  def initialize
    @stack = [ {} of String => Int32 | Bool | Function ]
  end

  def generate(ast : ASTNode)
    visit ast
  end

  def visit(node : Nop)
  end

  def visit(node : Statements)
    rtn = nil
    node.each do |n|
      rtn = visit n
    end
    rtn
  end

  def visit(node : Define)
    name = node.variable_name
    exp = node.exp

    value = visit(exp)
    raise_type(exp) if value.nil?
    store_variable(name, value)
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
    fetch_variable(node.name, node)
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
    clone = node.clone
    clone.closure = snapshot_stack
    clone
  end

  def visit(node : Call) : Bool | Int32 | Function | Nil
    if func_name = node.func.as? String
      func = fetch_variable func_name, node
      raise "`#{node.func}` is not a function", node unless func.is_a? Function
    else
      func = node.func
    end
    func = func.as Function

    raise "Wrong number of arguments `#{node.params.size}`, expecting `#{func.args.size}`" unless node.params.size == func.args.size
    args = {} of String => Bool | Int32 | Function
    node.params.size.times do |i|
      v = visit(node.params[i])
      raise "Argument `#{func.args[i]}` should not be null", node if v.nil?
      args[func.args[i]] = v.not_nil!
    end

    level = apply_snapshot func.closure
    create_stack_layer
    # apply arguments
    args.each do |k, v|
      store_variable(k, v)
    end
    rtn = visit(Statements.from func.exps.map { |e| e.as ASTNode } )
    (level + 1).times { @stack.pop }

    rtn
  end

  private def create_stack_layer
    @stack << {} of String => Bool | Int32 | Function
  end

  private def snapshot_stack
    @stack.dup
  end

  private def apply_snapshot(snapshot)
    return 0 if snapshot.nil?
    top = {@stack.size, snapshot.size}.min
    i = 0
    while i < top && @stack[i].object_id == snapshot[i].object_id
      i += 1
    end
    # applying
    @stack.concat snapshot[i..-1] if i < snapshot.size
    snapshot.size - i
  end

  private def store_variable(name : String, value : Bool | Int32 | Function)
    @stack.last[name] = value
  end

  private def fetch_variable(name : String, node)
    @stack.reverse_each do |vars|
      return vars[name] if vars.has_key? name
    end
    raise "Undefined variable: `#{name}`", node
  end

  private def raise_type(node, expected_type : Symbol? = nil)
    raise "Unexpected type", node if expected_type.nil?
    raise "Unexpected type, expecting `#{expected_type}`", node
  end

  private def raise(msg, node)
    ::raise RuntimeError.new(msg, node.location)
  end
end
