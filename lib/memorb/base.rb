module Memorb
  module Base

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:prepend, InstanceMethods)
    end

  end
end
