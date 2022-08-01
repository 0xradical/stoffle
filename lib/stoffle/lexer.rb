require_relative "./location"

module Stoffle
  class Lexer
    attr_accessor :next_p, :lexeme_start_p, :tokens, :line
    attr_reader :source

    WHITESPACE = [" ", "\t"]
    ONE_CHAR_LEX = [
      "(", ":", ",", ".", "+", ")",
      "-", "*", "/", '"', '#',"\n"
    ]
    ONE_OR_TWO_CHAR_LEX = [
      "=", "!", ">", "<"
    ]
    KEYWORD = [
      "true", "false", "and", "or",
      "if", "else", "elsif", "end",
      "fn", "return", "while", "println",
      "nil"
    ]


    def initialize(source)
      @source = source
      @length = source.length
      @tokens = []
      @line = 0
      @next_p = 0
      @lexeme_start_p = 0
    end

    def start_tokenization
      while source_uncompleted?
        tokenize
      end

      tokens << Token.new(:eof, '', nil, after_source_end_location)

      tokens
    end

    def source_uncompleted?
      @length > @lexeme_start_p + 1
    end

    def token_from_one_char_lex(c)
      Token.new(c.to_sym, c, nil, current_location)
    end

    def token_from_one_or_two_char_lex(c)
      if lookahead == "="
        lexeme = c + consume
      else
        lexeme = c
      end

      Token.new(lexeme.to_sym, lexeme, nil, current_location)
    end

    def tokenize
      self.lexeme_start_p = self.next_p
      token = nil

      c = consume

      return if WHITESPACE.include?(c)

      return ignore_comment_line if c == '#'

      if c == "\n"
        self.line += 1
        tokens << token_from_one_char_lex(c) if tokens.last&.type != :"\n"

        return
      end

      token =
        if ONE_CHAR_LEX.include?(c)
          token_from_one_char_lex(c)
        elsif ONE_OR_TWO_CHAR_LEX.include?(c)
          token_from_one_or_two_char_lex(c)
        elsif c == '"'
          string
        elsif digit?(c)
          number
        elsif alpha_numeric?(c)
          identifier
        end

      if token
        self.tokens << token
      else
        raise("Unknown character: #{c}")
      end
    end

    def lookahead(offset = 1)
      lookahead_p = (next_p - 1) + offset
      return "\0" if lookahead_p >= @length

      source[lookahead_p]
    end

    def consume
      c = lookahead
      self.next_p += 1
      c
    end

    def digit?(character)
      character =~ /\A[[:digit:]]\Z/
    end

    def alpha_numeric?(character)
      character =~ /\A[[:alnum:]_]\Z/
    end

    def current_location
      Location.new(@line, @lexeme_start_p, @next_p - @lexeme_start_p + 1)
    end

    def after_source_end_location
      Location.new(@line, @next_p, 0)
    end

    def string
      loop do
        consume
        self.line += 1 if lookahead == "\n"

        break if lookahead == '"'
        raise 'Unterminated string error' if source_completed?
      end

      # consume the closing '"'
      consume
      lexeme = source[(lexeme_start_p)..(next_p - 1)]
      literal = source[(lexeme_start_p + 1)..(next_p - 2)]

      Token.new(:string, lexeme, literal, current_location)
    end

    def consume_digits
      consume while digit?(lookahead)
    end

    def number
      consume_digits

      if lookahead == '.' && digit?(lookahead(2))
        consume # the '.' character
        consume_digits
      end

      lexeme = source[lexeme_start_p..(next_p - 1)]
      Token.new(:number, lexeme, lexeme.to_f, current_location)
    end

    def identifier
      consume while alpha_numeric?(lookahead)

      identifier = source[lexeme_start_p..(next_p - 1)]
      type =
        if KEYWORD.include?(identifier)
          identifier.to_sym
        else
          :identifier
        end

      Token.new(type, identifier, nil, current_location)
    end
  end
end