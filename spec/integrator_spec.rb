class BasicIntegrator < Counter
  include Memorb
end

class ChildIntegrator < BasicIntegrator
end

class DuplicateIntegrator < Counter
  include Memorb
  include Memorb
end

class ChildDuplicateIntegrator < BasicIntegrator
  include Memorb
end

class EnumerativeWithBracketsIntegrator < Counter
  include Memorb[:increment, :double]
end

class EnumerativeWithParenthesesIntegrator < Counter
  include Memorb(:increment, :double)
end

class PrependedBasicIntegrator < Counter
  prepend Memorb
end

class PrependedEnumerativeIntegrator < Counter
  prepend Memorb[:increment, :double]
end

RSpec.shared_examples 'an integrator' do
  let(:integrator) { described_class }
  let(:instance) { integrator.new }
  let(:integration) { Memorb::Integration[integrator] }

  it 'has the correct ancestry' do
    ancestors = integrator.ancestors
    expected_ancestry = [integration, integrator]
    relevant_ancestors = ancestors.select { |a| expected_ancestry.include? a }
    expect(relevant_ancestors).to match_array(expected_ancestry)
  end
end

RSpec.shared_examples 'a registered integrator' do
  let(:integrator) { described_class }

  it 'registers #increment' do
    integration = Memorb::Integration[integrator]
    expect(integration.public_instance_methods).to include(:increment)
  end
  it 'registers #double' do
    integration = Memorb::Integration[integrator]
    expect(integration.public_instance_methods).to include(:double)
  end
end

RSpec.describe BasicIntegrator do
  it_behaves_like 'an integrator'
end

RSpec.describe ChildIntegrator do
  it_behaves_like 'an integrator'
end

RSpec.describe DuplicateIntegrator do
  it_behaves_like 'an integrator'
end

RSpec.describe ChildDuplicateIntegrator do
  it_behaves_like 'an integrator'
end

RSpec.describe EnumerativeWithBracketsIntegrator do
  it_behaves_like 'an integrator'
  it_behaves_like 'a registered integrator'
end

RSpec.describe EnumerativeWithParenthesesIntegrator do
  it_behaves_like 'an integrator'
  it_behaves_like 'a registered integrator'
end

RSpec.describe PrependedBasicIntegrator do
  it_behaves_like 'an integrator'
end

RSpec.describe PrependedEnumerativeIntegrator do
  it_behaves_like 'an integrator'
  it_behaves_like 'a registered integrator'
end
