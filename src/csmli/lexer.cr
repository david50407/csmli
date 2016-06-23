require "string_pool"

class Csmli::Lexer
  @string_pool : StringPool

  getter token : Token
  property skip : Bool
  private getter current_char

  def initialize(@io : IO, string_pool : StringPool? = nil)
    @token = Token.new
    @line_number = 1
    @column_number = 1
    @buffer = [] of Char
    @last_buffer = [] of Char
    @skip = false
    @current_char = @io.read_char || '\0'
    @string_pool = string_pool || StringPool.new
  end

  def next_token
    start_buffer
    skip_whitespace

    @token.line_number = @line_number
    @token.column_number = @column_number

    case current_char
    when '\0'
      @token.type = :EOF
    when '('
      next_char :"("
    when ')'
      next_char :")"
    when '+'
      next_char :+
    when '-'
      case next_char
      when '1'..'9'
        consume_number negative: true
      else
        @token.type = :-
      end
    when '*'
      next_char :*
    when '/'
      next_char :/
    when '>'
      next_char :>
    when '<'
      next_char :<
    when '='
      next_char :"="
    when '#'
      consume_bool
    when '0'
      consume_zero_number
    when '1'..'9'
      consume_number
    when 'a'
      if buffered_next_char == 'n' && buffered_next_char == 'd'
        commit_buffer
        next_char :and
      else
        consume_ident
      end
    when 'd'
      if buffered_next_char == 'e' && buffered_next_char == 'f' && buffered_next_char == 'i' &&
          buffered_next_char == 'n' && buffered_next_char == 'e'
        commit_buffer
        next_char :define
      else
        consume_ident
      end
    when 'f'
      if buffered_next_char == 'u' && buffered_next_char == 'n'
        commit_buffer
        next_char :fun
      else
        consume_ident
      end
    when 'i'
      if buffered_next_char == 'f'
        commit_buffer
        next_char :if
      else
        consume_ident
      end
    when 'm'
      if buffered_next_char == 'o' && buffered_next_char == 'd'
        commit_buffer
        next_char :mod
      else
        consume_ident
      end
    when 'n'
      if buffered_next_char == 'o' && buffered_next_char == 't'
        commit_buffer
        next_char :not
      else
        consume_ident
      end
    when 'o'
      if buffered_next_char == 'r'
        commit_buffer
        next_char :or
      else
        consume_ident
      end
    when 'p'
      if buffered_next_char == 'r' && buffered_next_char == 'i' && buffered_next_char == 'n' &&
          buffered_next_char == 't' && buffered_next_char == '-'
        type = {buffered_next_char, buffered_next_char, buffered_next_char}
        if type == {'n', 'u', 'm'}
          commit_buffer
          next_char :"print-num"
        elsif type == {'b', 'o', 'o'} && buffered_next_char == 'l'
          commit_buffer
          next_char :"print-bool"
        else
          consume_ident
        end
      else
        consume_ident
      end
    else
      if current_char.lowercase?
        consume_ident
      else
        unexpected_char
      end
    end

    @token
  end

  private def consume_bool
    case next_char
    when 'f'
      next_char :false
    when 't'
      next_char :true
    else
      unexpected_char
    end
  end

  private def consume_ident
    buf = MemoryIO.new
    while current_char.lowercase? || current_char.digit? || current_char == '-'
      buf << current_char
      next_char
    end
    @token.type = :ident
    @token.value = @string_pool.get buf.to_s
  end

  private def consume_number(negative = false)
    val = (current_char - '0').to_i64
    while '0' <= next_char <= '9'
      val *= 10
      val += current_char - '0'
    end
    @token.type = :number
    @token.number_value = (negative ? -val : val).to_i32
  end

  private def consume_zero_number
    case next_char
    when '0'..'9'
      unexpected_char
    else
      @token.type = :number
      @token.number_value = 0_i32
    end
  end

  private def skip_whitespace
    while whitespace?(current_char)
      if current_char == '\n'
        @line_number += 1
        @column_number = 0
      end
      next_char
    end
  end

  private def whitespace?(char)
    case char
    when '\t', '\n', '\r', ' '
      true
    else
      false
    end
  end

  private def start_buffer
    @last_buffer = @buffer + @last_buffer
    @buffer.clear
  end

  private def buffered_next_char
    if char = @io.read_char
      @buffer << char
      char
    else
      '\0'
    end
  end

  private def read_next_char
    @last_buffer.shift? || @io.read_char || '\0'
  end

  private def next_char
    @column_number += 1
    @current_char = @buffer.shift? || read_next_char
  end

  private def next_char(token_type)
    @token.type = token_type
    next_char
  end

  private def commit_buffer
    @column_number += @buffer.size
    @buffer.clear
  end

  private def unexpected_char
    raise "Unexpected char '#{current_char}'"
  end

  private def raise(msg)
    ::raise ParseException.new(msg, @line_number, @column_number)
  end
end
