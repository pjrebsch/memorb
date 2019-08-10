module Memorb
  module IntegratorClassMethods

    def inherited(child)
      Integration.integrate_with!(child)
      super
    end

    def memorb
      Integration[self]
    end

  end
end
