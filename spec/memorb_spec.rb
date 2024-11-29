# frozen_string_literal: true

describe ::Memorb do
  context 'when integrating improperly' do
    let(:error) { ::Memorb::InvalidIntegrationError }
    let(:error_message) { 'Memorb must be integrated using `extend`' }

    context 'when included on a target' do
      it 'raises an error' do
        expect {
          ::Class.new { include ::Memorb }
        }.to raise_error(error, error_message)
      end
    end
    context 'when prepended on a target' do
      it 'raises an error' do
        expect {
          ::Class.new { prepend ::Memorb }
        }.to raise_error(error, error_message)
      end
    end
  end

  describe 'integrators' do
    shared_examples 'for ancestry verification' do
      it 'has the correct ancestry' do
        expect(integration).not_to be(nil)
        ancestors = integrator.ancestors
        expected_ancestry = [integration, integrator]
        relevant_ancestors = ancestors.select { |a| expected_ancestry.include?(a) }
        expect(relevant_ancestors).to match_array(expected_ancestry)
      end
    end

    let(:integration) { ::Memorb::Integration[integrator] }
    let(:instance) { integrator.new }

    describe 'a basic integrator' do
      let(:integrator) {
        ::Class.new do
          extend ::Memorb
        end
      }
      include_examples 'for ancestry verification'
    end

    describe 'an integrator that includes Memorb more than once' do
      let(:integrator) {
        ::Class.new do
          extend ::Memorb
          extend ::Memorb
        end
      }
      include_examples 'for ancestry verification'
    end

    describe 'a child of an integrator' do
      let(:parent_integrator) {
        ::Class.new do
          extend ::Memorb
        end
      }
      let(:integrator) {
        ::Class.new(parent_integrator)
      }
      include_examples 'for ancestry verification'
    end

    describe 'a child of an integrator that includes Memorb again' do
      let(:parent_integrator) {
        ::Class.new do
          extend ::Memorb
        end
      }
      let(:integrator) {
        ::Class.new(parent_integrator) do
          extend ::Memorb
        end
      }
      include_examples 'for ancestry verification'
    end

    describe 'an integrator that aliases a method after registration' do
      let(:integrator) {
        ::Class.new(::SpecHelper.basic_target_class) do
          extend ::Memorb
          memorb.register(:increment)
          alias_method :other_increment, :increment
        end
      }

      it 'implements caching for the aliased method' do
        result_1 = instance.other_increment
        result_2 = instance.other_increment
        expect(result_1).to eq(result_2)
      end
    end

    describe 'an integrator that aliases a method before registration' do
      let(:integrator) {
        ::Class.new(::SpecHelper.basic_target_class) do
          extend ::Memorb
          alias_method :other_increment, :increment
          memorb.register(:increment)
        end
      }

      it 'does not implement caching for the aliased method' do
        result_1 = instance.other_increment
        result_2 = instance.other_increment
        expect(result_1).not_to eq(result_2)
      end
    end

    describe 'an integrator that uses alias method chaining' do
      let(:integrator) {
        ::Class.new(::SpecHelper.basic_target_class) do
          extend ::Memorb
          memorb.register(:increment)
          def new_increment; old_increment; end
          alias_method :old_increment, :increment
          alias_method :increment, :new_increment
        end
      }

      it 'results in infinite recursion when the method is called' do
        error = case ::RUBY_ENGINE
        when 'jruby'
          [java.lang.StackOverflowError]
        else
          [::SystemStackError, 'stack level too deep']
        end
        expect { instance.increment }.to raise_error(*error)
      end
    end

    describe 'an integrator with a method that accepts a block' do
      let(:integrator) {
        ::Class.new(::SpecHelper.basic_target_class) do
          extend ::Memorb
          def with_block(&block); block ? block.call(self) : increment; end
          memorb.register(:with_block)
        end
      }

      it 'still gets the block as a parameter' do
        result = instance.with_block { |x| x }
        expect(result).to be(instance)
      end

      it 'considers calls with different blocks to have the same arguments' do
        result_1 = instance.with_block { |x| x.increment }
        result_2 = instance.with_block { |x| x.increment }
        expect(result_1).to eq(result_2)
      end

      it 'considers calls with different proc-blocks to have the same arguments' do
        proc_1 = ::Proc.new { |x| x.increment }
        proc_2 = ::Proc.new { |x| x.increment }
        result_1 = instance.with_block(&proc_1)
        result_2 = instance.with_block(&proc_2)
        expect(result_1).to eq(result_2)
      end

      it 'considers a call with a block to be the same as a call without one' do
        result_1 = instance.with_block { |x| x.increment }
        result_2 = instance.with_block
        expect(result_1).to eq(result_2)
      end
    end

    ::SpecHelper.for_testing_garbage_collection do
      let(:integrator) {
        ::Class.new(::SpecHelper.basic_target_class) do
          extend ::Memorb
          memorb.register(:noop)
        end
      }

      describe 'a method argument for a memoized method' do
        xit 'allows the argument to be garbage collected' do
          ref = ::WeakRef.new(Object.new)
          instance.send(:noop, ref.__getobj__)
          ::SpecHelper.force_garbage_collection
          expect(ref.weakref_alive?).to be_falsey
        end
      end
      describe 'a low-level cache fetch' do
        xit 'allows the cache key to be garbage collected' do
          ref = ::WeakRef.new(Object.new)
          instance.memorb.fetch(ref.__getobj__) { nil }
          ::SpecHelper.force_garbage_collection
          expect(ref.weakref_alive?).to be_falsey
        end
      end
    end
  end
end
