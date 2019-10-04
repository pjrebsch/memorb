# frozen_string_literal: true

require 'concurrent'

module Memorb
  class KeyValueStore

    def initialize
      @data = ::Hash.new
      @lock = ::Concurrent::ReentrantReadWriteLock.new
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
        return _read(key) if _has?(key)
      end
      # Concurrent readers could all see no entry if none were able to
      # write before the others checked for the key, so they need to be
      # synchronized below to ensure that only one of them actually
      # executes the fallback block and writes the resulting value.
      @lock.with_write_lock do
        # The first thread to acquire the write lock will write the value
        # for the key causing the other aforementioned threads that may
        # also want to write to now see the key and return it.
        _has?(key) ? _read(key) : _write(key, fallback.call)
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
