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
      memorb.override_if_possible(name)
      super
    end

  end
end
