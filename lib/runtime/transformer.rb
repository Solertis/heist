# Quotations taken from the R5RS spec
# http://www.schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-7.html
module Heist
  class Runtime
    
    class Transformer < Function
      ELLIPSIS = '...'
      
      def initialize(*args)
        super
        @renames = {}
      end
      
      # TODO:   * throw an error if no rules match
      def call(scope, cells)
        rule, bindings = *rule_for(cells, scope)
        return nil unless rule
        expanded = expand_template(rule[1..-1], bindings)
        expanded.map { |part| Heist.value_of(part, scope) }.last
      end
      
    private
      
      def rule_for(cells, scope)
        @body.each do |rule|
          bindings = rule_bindings(rule.first[1..-1], cells)
          return [rule, bindings] if bindings
        end
        nil
      end
      
      # More formally, an input form F matches a pattern P if and only if:
      # 
      #     * P is a non-literal identifier; or
      #     * P is a literal identifier and F is an identifier with the
      #       same binding; or
      #     * P is a list (P1 ... Pn) and F is a list of n forms that match
      #       P1 through Pn, respectively; or
      #     * P is an improper list (P1 P2 ... Pn . Pn+1) and F is a list
      #       or improper list of n or more forms that match P1 through Pn,
      #       respectively, and whose nth 'cdr' matches Pn+1; or
      #     * P is of the form (P1 ... Pn Pn+1 <ellipsis>) where <ellipsis>
      #       is the identifier '...' and F is a proper list of at least n forms,
      #       the first n of which match P1 through Pn, respectively, and
      #       each remaining element of F matches Pn+1; or
      #     * P is a vector of the form #(P1 ... Pn) and F is a vector of n
      #       forms that match P1 through Pn; or
      #     * P is of the form #(P1 ... Pn Pn+1 <ellipsis>) where <ellipsis>
      #       is the identifier '...' and F is a vector of n or more forms the
      #       first n of which match P1 through Pn, respectively, and each
      #       remaining element of F matches Pn+1; or
      #     * P is a datum and F is equal to P in the sense of the 'equal?'
      #       procedure.
      # 
      # It is an error to use a macro keyword, within the scope of its
      # binding, in an expression that does not match any of the patterns.
      # 
      def rule_bindings(tokens, input, bindings = nil)
        bindings ||= Scope.new
        
        return nil if input.size > tokens.size &&
                      tokens.last.to_s != ELLIPSIS
        
        tokens.each_with_index do |token, i|
          case token
            # TODO handle improper lists and vectors
            #      when they are implemented
            
            when List then
              return nil unless List === input[i]
              value = rule_bindings(token, input[i], bindings)
              return nil if value.nil?
            
            when Identifier then
              if tokens[i+1].to_s == ELLIPSIS
                bindings[token] = Splice.new(input[i..-1])
                break
              else
                return nil unless input[i]
                bindings[token] = input[i]
              end
            
            else
              return nil unless token == input[i]
          end
        end
        bindings
      end
      
      # When a macro use is transcribed according to the template of the
      # matching <syntax rule>, pattern variables that occur in the template
      # are replaced by the subforms they match in the input. Pattern variables
      # that occur in subpatterns followed by one or more instances of the
      # identifier '...' are allowed only in subtemplates that are followed
      # by as many instances of '...'. They are replaced in the output by all
      # of the subforms they match in the input, distributed as indicated. It
      # is an error if the output cannot be built up as specified.
      # 
      # Identifiers that appear in the template but are not pattern variables
      # or the identifier '...' are inserted into the output as literal
      # identifiers. If a literal identifier is inserted as a free identifier
      # then it refers to the binding of that identifier within whose scope
      # the instance of 'syntax-rules' appears. If a literal identifier is
      # inserted as a bound identifier then it is in effect renamed to prevent
      # inadvertent captures of free identifiers.
      # 
      def expand_template(template, bindings)
        result = template.class.new
        last_splice = nil
        template.each do |cell|
          case cell
          
          when List then
            result << expand_template(cell, bindings)
          
          when Identifier then
            if cell.to_s == ELLIPSIS
              last_splice.cells.each { |cell| result << cell }
            else
              binding_scope = [bindings, @scope].find { |env| env.defined?(cell) }
              value = binding_scope ? binding_scope[cell] : rename(cell)
              
              if Splice === value
                last_splice = value
              else
                result << value
              end
            end
            
          else
            result << cell
          end
        end
        result
      end
      
      def rename(identifier)
        @renames[identifier.to_s] ||= Identifier.new("__#{identifier}__")
      end
    end
    
    class Splice
      attr_reader :cells
      def initialize(cells)
        @cells = cells
      end
    end
    
  end
end

