# frozen_string_literal: true

module Memorb
  class Agent

    def initialize(id)
      @id = id
      @store = KeyValueStore.new
    end

    attr_reader :id

    def method_store
      store.fetch(:methods) { KeyValueStore.new }
    end

    def value_store
      store.fetch(:value) { KeyValueStore.new }
    end

    def fetch(key, &block)
      value_store.fetch(key, &block)
    end

    private

    attr_reader :store

  end
end
