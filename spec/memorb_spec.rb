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
  end
end
