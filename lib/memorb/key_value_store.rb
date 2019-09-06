# frozen_string_literal: true

require 'concurrent'

module Memorb
  # KeyValueStore is a thread-safe key-value store.
  #
  # Thread safety is important here because an implementing class may
  # be using Memorb and expecting that a cacheable method be executed
  # only once. When a cacheable method is called, Memorb calls #fetch
  # on this KeyValueStore and expects it to be an atomic operation.
  # Without thread safety, a TOCTOU bug exists with the #fetch method where
  # another thread could write to a given key in the cache after #fetch
  # has determined that the key doesn't exist yet, causing a double-write
  # to the cache (or possibly a double-execution of the original cacheable
  # method).
  #
  class KeyValueStore

    def initialize
      @data = {}
      @lock = Concurrent::ReentrantReadWriteLock.new
    end

    attr_reader :lock

    def write(key, value)
      @lock.with_write_lock { _write(key, value) }
    end

    def read(key)
      @lock.with_read_lock { _read(key) }
    end

    def has?(key)
      @lock.with_read_lock { _has?(key) }
    end

    def fetch(key, &fallback)
      @lock.with_read_lock do
        _has?(key) ? _read(key) : write(key, fallback.call)
      end
    end

    def forget(key)
      @lock.with_write_lock { _forget(key) }
    end

    def reset!
      @lock.with_write_lock { _reset! }
    end

    def keys
      @lock.with_read_lock { _keys }
    end

    def inspect
      "#<#{ self.class.name } keys=#{ keys.inspect }>"
    end

    private

    def _write(key, value)
      @data[key] = value
    end

    def _read(key)
      @data[key]
    end

    def _has?(key)
      @data.include?(key)
    end

    def _forget(key)
      @data.delete(key)
      nil
    end

    def _reset!
      @data.clear
      nil
    end

    def _keys
      @data.keys
    end

  end
end
