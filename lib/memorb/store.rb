module Memorb
  class Store

    def initialize
      @data = {}
    end

    def write(key, value)
      @data[key] = value
    end

    def read(key)
      @data[key]
    end

    def has?(key)
      @data.include?(key)
    end

    def fetch(key, &fallback)
      has?(key) ? read(key) : write(key, fallback.call)
    end

  end
end
