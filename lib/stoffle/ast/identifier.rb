require_relative "./expression"

module Stoffle
  module AST
    class Identifier < Expression
      attr_accessor :name

      def initialize(name)
        @name = name
      end

      def ==(other)
        name == other.name
      end

      def children
        []
      end
    end
  end
end