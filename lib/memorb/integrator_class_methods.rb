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
        # Re-register the method so that it now gets overridden.
        memorb.register(name) if memorb.registered?(name)
      end
    end

  end
end
