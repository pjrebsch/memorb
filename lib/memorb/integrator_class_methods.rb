# frozen_string_literal: true

module Memorb
  module IntegratorClassMethods

    def inherited(child)
      Integration.integrate_with!(child)
      super
    end

    def memorb
      Integration[self]
    end

    def method_added(name)
      super.tap do
        memorb.enable(name)
      end
    end

    def method_removed(name)
      super.tap do
        memorb.disable(name)
      end
    end

  end
end
