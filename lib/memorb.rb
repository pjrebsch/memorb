require_relative 'memorb/store'
require_relative 'memorb/mixin'
require_relative 'memorb/cache'

module Memorb

  class << self
    def [](*methods)
      self
    end

    def included(base)
      Mixin.mixin(base)
    end
  end

end
