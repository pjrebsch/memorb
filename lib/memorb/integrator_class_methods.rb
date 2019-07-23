module Memorb
  module IntegratorClassMethods

    def inherited(child)
      Mixin.mixin!(child)
    end

    def memorb
      Mixin.for(self)
    end

  end
end
