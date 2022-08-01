require_relative "./ast"

module Stoffle
  class Parser
    attr_accessor :tokens, :ast, :errors, :next_p

    def initialize(tokens)
      @tokens = tokens
      @ast = AST::Program.new
      @next_p = 0
      @errors = []
    end

    def pending_tokens?
      @next_p < @tokens.length
    end

    def current
      @tokens[@next_p - 1]
    end

    def lookahead(offset = 1)
      lookahead_p = (@next_p - 1) + offset

      return nil if lookahead_p >= @tokens.length

      @tokens[lookahead_p]
    end

    def consume
      c = current
      self.next_p += 1
      c
    end

    def parse
      while pending_tokens?
        consume

        node = parse_expr_recursively
        ast << node if node != nil
      end
    end

    def parse_expr_recursively
      parsing_function = determine_parsing_function

      if parsing_function.nil?
        unrecognized_token_error
        return
      end

      self.public_send(parsing_function)
    end

    def determine_parsing_function
      if [
        :return, :identifier, :number, :string,
        :true, :false, :nil, :fn, :if, :while
      ].include?(current.type)
        "parse_#{current.type}".to_sym
      elsif current.type == :"("
        :parse_grouped_expr
      elsif [:"\n", :eof].include?(current.type)
        :parse_terminator
      elsif UNARY_OPERATORS.include?(current.type)
        :parse_unary_operator
      end
    end

    def parse_identifier
      lookahead.type == :'=' ? parse_var_binding : AST::Identifier.new(current.lexeme)
    end

    def parse_var_binding
      identifier = AST::Identifier.new(current.lexeme)

      # = [ something ]
      consume(2)

      AST::VarBinding.new(identifier, parse_expr_recursively)
    end
  end
end