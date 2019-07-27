RSpec.shared_examples 'for ancestry verification' do
  let(:integration) { Memorb::Integration[integrator] }

  it 'has the correct ancestry' do
    ancestors = integrator.ancestors
    expected_ancestry = [integration, integrator]
    relevant_ancestors = ancestors.select { |a| expected_ancestry.include? a }
    expect(relevant_ancestors).to match_array(expected_ancestry)
  end
end

RSpec.shared_examples 'for method registration verification' do
  it 'registers #increment' do
    integration = Memorb::Integration[integrator]
    expect(integration.public_instance_methods).to include(:increment)
  end
  it 'registers #double' do
    integration = Memorb::Integration[integrator]
    expect(integration.public_instance_methods).to include(:double)
  end
end

RSpec.describe 'integrators of Memorb' do
  describe 'a basic integrator' do
    let(:integrator) {
      Class.new do
        include Memorb
      end
    }
    include_examples 'for ancestry verification'
  end

  describe 'a basic integrator that uses prepend' do
    let(:integrator) {
      Class.new do
        prepend Memorb
      end
    }
    include_examples 'for ancestry verification'
  end

  describe 'an integrator that includes Memorb more than once' do
    let(:integrator) {
      Class.new do
        include Memorb
        include Memorb
      end
    }
    include_examples 'for ancestry verification'
  end

  describe 'a child of an integrator' do
    let(:parent_integrator) {
      Class.new do
        include Memorb
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
        include Memorb
      end
    }
    let(:integrator) {
      Class.new(parent_integrator) do
        include Memorb
      end
    }
    include_examples 'for ancestry verification'
  end

  describe 'an integrator that registers methods with inclusion' do
    let(:integrator) {
      Class.new(Counter) do
        include Memorb[:increment, :double]
      end
    }
    include_examples 'for ancestry verification'
    include_examples 'for method registration verification'
  end

  describe 'an integrator that registers methods with inclusion using parentheses' do
    let(:integrator) {
      Class.new(Counter) do
        include Memorb(:increment, :double)
      end
    }
    include_examples 'for ancestry verification'
    include_examples 'for method registration verification'
  end
end
