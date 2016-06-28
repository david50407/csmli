require "./ast_node"

class Csmli::Parser
  @lexer : Lexer

  private getter token : Token

  def initialize(io : IO)
    @token = Token.new
    @lexer = Lexer.new(io)
    @buffer = [] of Token
    @last_buffer = [] of Token
  end

  def parse
    next_token
    exps = parse_statements

    check :EOF

    exps
  end

  def parse_statements
    return Nop.new if end_token?

    stmts = [] of ASTNode
    loop do
      stmts << parse_statement
      break if end_token?
    end

    Statements.from stmts
  end

  def parse_statement
    case token.type
    when :"("
      case buffered_next_token.type
      when :define
        return parse_define
      when :"print-num"
        return parse_print
      end
    end

    parse_expression
  end

  def parse_define
    line_number = token.line_number
    column_number = token.column_number

    check(:"(") && next_token
    check(:define) && next_token
    check(:ident)
    node = Define.new token.value
    next_token
    node.exp = parse_expression
    node.at Location.new(line_number, column_number)
    check(:")") && next_token

    node
  end

  def parse_print
    line_number = token.line_number
    column_number = token.column_number

    check(:"(") && next_token
    case token.type
    when :"print-num"
      node = Print.new :num
    when :"print-bool"
      node = Print.new :bool
    else
      raise "Unexpected token `#{token.type}` (expecting `print-num`, `print-bool`)"
    end
    next_token
    node.exp = parse_expression
    node.at Location.new(line_number, column_number)
    check(:")") && next_token

    node
  end

  def parse_expression
    line_number = token.line_number
    column_number = token.column_number

    case token.type
    when :true
      node = Boolean.new true
    when :false
      node = Boolean.new false
    when :number
      node = Number.new token.number_value
    when :ident
      node = Variable.new token.value
    when :"("
      case next_token.type
      when :+, :*, :"=", :and, :or
        node = Operation.new token.type
        next_token
        node.args << parse_expression
        node.args << parse_expression
        while exp_start_token?
          node.args << parse_expression
        end
      when :-, :/, :mod, :>, :<
        node = Operation.new token.type
        next_token
        node.args << parse_expression
        node.args << parse_expression
      when :not
        node = Operation.new :not
        next_token
        node.args << parse_expression
      when :fun
        next_token
        node = parse_function_internal
      when :if
        next_token
        node = If.new
        node.test_exp = parse_expression
        node.then_exp = parse_expression
        node.else_exp = parse_expression
      when :ident # fun-name call
        node = Call.new token.value
        next_token
        while exp_start_token?
          node.params << parse_expression
        end
      when :"(" # fun-exp call
        next_token
        check(:fun) && next_token
        node = Call.new parse_function_internal
        check(:")") && next_token
        while exp_start_token?
          node.params << parse_expression
        end
      else
        raise "Unexpected token `#{token.type}`"
      end
      check(:")")
    else
      raise "Unexpected token `#{token.type}`"
    end

    node.at Location.new(line_number, column_number)
    node.at_end Location.new(token.line_number, token.column_number)
    next_token

    node
  end

  def parse_function_internal
    node = Function.new
    check(:"(") && next_token
    while token.type == :ident
      node.args << token.value
      next_token
    end
    check(:")") && next_token
    while token.type == :"(" && buffered_next_token.type == :define
      node.defs << parse_define
    end
    node.exp = parse_expression

    node
  end

  def raise(msg)
    ::raise ParseException.new(msg, token.line_number, token.column_number)
  end

  def check(token_type)
    raise "Unexpected token `#{token.type}` (expected `#{token_type}`)" unless token_type == token.type
    true
  end

  def exp_start_token?
    case token.type
    when :number, :true, :false, :ident, :"("
      true
    else
      false
    end
  end

  def end_token?
    token.type == :EOF
  end

  def next_token
    @token = @buffer.shift? || @lexer.next_token
  end

  def buffered_next_token
    token = @lexer.next_token
    @buffer << token unless token.type == :EOF
    token
  end

  def commit_buffer
    @token = @buffer.last if @buffer.size > 0
    @buffer.clear
  end
end
