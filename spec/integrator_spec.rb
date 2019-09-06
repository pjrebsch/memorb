# frozen_string_literal: true

RSpec.shared_examples 'for ancestry verification' do
  it 'has the correct ancestry' do
    expect(integration).not_to be(nil)
    ancestors = integrator.ancestors
    expected_ancestry = [integration, integrator]
    relevant_ancestors = ancestors.select { |a| expected_ancestry.include? a }
    expect(relevant_ancestors).to match_array(expected_ancestry)
  end
end

RSpec.shared_examples 'for method registration verification' do |methods|
  it 'registers the correct methods' do
    expect(integration.registered_methods).to include(:increment, :double)
  end
end

RSpec.describe 'integrators of Memorb' do
  let(:target) { SpecHelper.basic_target_class }
  let(:integration) { Memorb::Integration[integrator] }

  describe 'a basic integrator' do
    let(:integrator) {
      Class.new do
        extend Memorb
      end
    }
    include_examples 'for ancestry verification'
  end

  describe 'an integrator that includes Memorb more than once' do
    let(:integrator) {
      Class.new do
        extend Memorb
        extend Memorb
      end
    }
    include_examples 'for ancestry verification'
  end

  describe 'a child of an integrator' do
    let(:parent_integrator) {
      Class.new do
        extend Memorb
      end
    }
    let(:integrator) {
      Class.new(parent_integrator)
    }
    include_examples 'for ancestry verification'
  end

  describe 'a child of an integrator that includes Memorb again' do
    let(:parent_integrator) {
      Class.new do
        extend Memorb
      end
    }
    let(:integrator) {
      Class.new(parent_integrator) do
        extend Memorb
      end
    }
    include_examples 'for ancestry verification'
  end

  describe 'an integrator that registers methods' do
    let(:integrator) {
      Class.new(target) do
        extend Memorb
        memorb.register(:increment)
        memorb.register(:double)
      end
    }
    include_examples 'for ancestry verification'
    include_examples 'for method registration verification'
  end

  describe 'an integrator that registers methods with inclusion' do
    let(:integrator) {
      Class.new(target) do
        extend Memorb[:increment, :double]
      end
    }
    include_examples 'for ancestry verification'
    include_examples 'for method registration verification'
  end

  describe 'an integrator that registers methods with inclusion using parentheses' do
    let(:integrator) {
      Class.new(target) do
        extend Memorb(:increment, :double)
      end
    }
    include_examples 'for ancestry verification'
    include_examples 'for method registration verification'
  end
end
