require_relative 'memorb/store'
require_relative 'memorb/mixin'
require_relative 'memorb/cache'
require_relative 'memorb/configurable'

module Memorb

  class << self
    def [](*args)
      Configurable.new(*args)
    end

    def included(base)
      Mixin.mixin(base)
    end
  end

end

def Memorb(*args)
  Memorb::Configurable.new(*args)
end
