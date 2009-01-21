require 'forwardable'

module Heist
  class Runtime
    
    %w(list identifier function frame scope binding).each do |file|
      require RUNTIME_PATH + file
    end
    
    extend Forwardable
    def_delegators(:@scope, :[], :eval, :run, :define, :metadef)
    
    attr_reader :order, :stack
    
    def initialize(options = {})
      @scope = Scope.new(self)
      @stack = []
      
      @order = options[:order] || EAGER
      
      instance_eval(File.read("#{ BUILTIN_PATH }common.rb"))
      instance_eval(File.read("#{ BUILTIN_PATH }#{ ORDERS[@order] }.rb"))
      Heist.run("#{ BUILTIN_PATH }common.scm", @scope)
      Heist.run("#{ BUILTIN_PATH }#{ ORDERS[@order] }.scm", @scope)
      
      @start_time = Time.now.to_f
    end
    
    def elapsed_time
      (Time.now.to_f - @start_time) * 1000000
    end
    
    def lazy?
      @order == NORMAL_ORDER
    end
    
  end
end
