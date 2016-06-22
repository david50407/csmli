class Csmli::Parser
  @lexer : Lexer

  def initialize(io : IO)
    @lexer = Lexer.new(io)
  end

  def parse
    next_token
    while token.type != :EOF
      puts token
      next_token
    end
  end

  private delegate token, to: @lexer
  private delegate next_token, to: @lexer
end
