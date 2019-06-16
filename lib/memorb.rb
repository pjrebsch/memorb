require 'set'

module Memorb

  module ClassMethods

    def method_added(name)
      # memorb_alias_chain_method(name)
    end

    private

    def memorb_alias_chain_method(name)
      return if Core::IGNORED_INSTANCE_METHODS.include? name
      return if just_added? name
      with = :"#{ name }_with_memorb"
      without = :"#{ name }_without_memorb"
      remember_method_additions(name, with, without)
      memorb_define_method(name, with, without)
      memorb_define_aliases(name, with, without)
      forget_method_additions
      puts "Aliased instance method: #{ name }"
    end

    def memorb_define_method(name, with, without)
      define_method(with) do |*args, &block|
        memorb_fetch(name, *args, block) do
          send(without, *args, &block)
        end
      end
    end

    def memorb_define_aliases(name, with, without)
      alias_method without, name
      alias_method name, with
    end

    def just_added?(name)
      @memorb_last_methods_added && @memorb_last_methods_added.include?(name)
    end

    def remember_method_additions(*names)
      @memorb_last_methods_added = names
    end

    def forget_method_additions
      @memorb_last_methods_added = nil
    end

  end

  module InstanceMethods

    def initialize(*)
      memorb_reset!
      super
    end

    def memorb_reset!
      @memorb_cache = Core.fresh_cache
      nil
    end

    def memorb_write(*key, value)
      @memorb_cache[key] = value
    end

    def memorb_read(*key)
      @memorb_cache[key]
    end

    def memorb_has?(*key)
      @memorb_cache.include?(key)
    end

    def memorb_fetch(*key, &fallback)
      memorb_has?(*key) ? memorb_read(*key) : memorb_write(*key, fallback.call)
    end

    def memorb_forget(*key)
      @memorb_cache.delete(key)
      nil
    end

  end

  module Core

    IGNORED_INSTANCE_METHODS = Set[:initialize, :new].freeze

    class << self

      def fresh_cache
        Hash.new
      end

    end
  end

  def self.included(base)
    base.extend(ClassMethods)
    base.send(:prepend, InstanceMethods)
  end

  # def c
  #   caller_locations(1, 1).first.label
  # end

end
