module Memorb
  module Mixin
    class << self

      @@mixins = Store.new

      def mixin(base)
        @@mixins.fetch(base) { mixin! base }
      end

      def for(klass)
        @@mixins.read(klass)
      end

      private

      def mixin!(base)
        new.tap do |m|
          base.extend ClassMethods
          base.prepend m
        end
      end

      def new
        Module.new do
          def self.prepended(base)
            @base_name = base.name
          end

          def self.name
            "Memorb(#{ @base_name })"
          end

          def self.inspect
            name
          end

          def self.register(name)
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{ name }(*args, &block)
                memorb.fetch(:"#{ name }", *args, block) do
                  super
                end
              end
            RUBY
          end

          def self.unregister(name)
            begin
              remove_method(name)
            rescue NameError
              # If attempting to unregister a method that isn't currently
              # registered, Ruby will raise an exception. Simply catching
              # it here makes the process of registering and unregistering
              # thread-safe.
            end
          end

          def initialize(*)
            @memorb_cache = Memorb::Cache.new(integration: self.class)
            super
          end

          def memorb
            @memorb_cache
          end
        end
      end

    end
  end
end
