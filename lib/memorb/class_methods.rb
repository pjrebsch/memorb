require 'set'

module Memorb
  module ClassMethods

    def inherited(child)
      Mixin.mixin(child)
    end

    def method_added(name)
      memorb_alias_chain_method(name)
    end

    private

    IGNORED_INSTANCE_METHODS = Set[:initialize].freeze

    def memorb_alias_chain_method(name)
      return if IGNORED_INSTANCE_METHODS.include? name
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
end
