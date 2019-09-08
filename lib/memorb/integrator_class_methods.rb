# frozen_string_literal: true

module Memorb
  module IntegratorClassMethods

    def memorb
      Integration[self]
    end

    private

    def inherited(child)
      super.tap do
        Integration.integrate_with!(child)
      end
    end

    def method_added(name)
      super.tap do
        memorb.enable(name)
      end
    end

    def method_removed(name)
      super.tap do
        memorb.disable(name)
        memorb.purge(name)
      end
    end

    def method_undefined(name)
      super.tap do
        memorb.disable(name)
        memorb.purge(name)
      end
    end

  end
end
