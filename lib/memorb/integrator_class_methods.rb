module Memorb
  module IntegratorClassMethods

    def inherited(child)
      Memorb.integrate! child
    end

    def memorb
      Memorb.integration(self)
    end

  end
end
