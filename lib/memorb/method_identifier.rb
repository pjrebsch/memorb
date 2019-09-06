module Memorb
  class MethodIdentifier

    def initialize(method_name)
      @method_name = method_name.to_sym
    end

    def hash
      self.class.hash ^ method_name.hash
    end

    def ==(other)
      hash === other.hash
    end

    alias_method :eql?, :==

    def to_s
      method_name.to_s
    end

    def to_sym
      method_name
    end

    protected

    attr_reader :method_name

  end
end
