# frozen_string_literal: true

describe ::Memorb::MethodIdentifier do
  let(:method_name) { :method_1 }
  subject { described_class.new(method_name) }

  describe '#hash' do
    it 'does not equal the hash of the method name symbol' do
      expect(subject.hash).not_to equal(method_name.hash)
    end
    context 'when given an other instance with the same method name' do
      it 'shares its hash value with the other instance' do
        subject_1 = described_class.new(method_name)
        subject_2 = described_class.new(method_name)
        expect(subject_1.hash).to equal(subject_2.hash)
      end
    end
    context 'when given an other instance with a different method name' do
      it 'does not share its hash value with the other instance' do
        subject_1 = described_class.new(:method_1)
        subject_2 = described_class.new(:method_2)
        expect(subject_1.hash).not_to equal(subject_2.hash)
      end
    end
  end
  describe '#eql?' do
    context 'when given an other instance with the same method name' do
      it 'returns true' do
        subject_1 = described_class.new(method_name)
        subject_2 = described_class.new(method_name)
        result = subject_1.eql?(subject_2)
        expect(result).to be(true)
      end
    end
    context 'when given an other instance with a different method name' do
      it 'returns false' do
        subject_1 = described_class.new(:method_1)
        subject_2 = described_class.new(:method_2)
        result = subject_1.eql?(subject_2)
        expect(result).to be(false)
      end
    end
  end
  describe '#==' do
    context 'when given an other instance with the same method name' do
      it 'is considered equal to the other instance' do
        subject_1 = described_class.new('method_1')
        subject_2 = described_class.new('method_1')
        expect(subject_1 == subject_2).to be(true)
      end
    end
    context 'when given an other instance with a different method name' do
      it 'is not considered equal to the other instance' do
        subject_1 = described_class.new('method_1')
        subject_2 = described_class.new('method_2')
        expect(subject_1 == subject_2).to be(false)
      end
    end
  end
  describe '#to_s' do
    it 'returns the originally provided method name as a string' do
      expect(subject.to_s).to eq('method_1')
    end
  end
  describe '#to_sym' do
    it 'returns the originally provided method name as a symbol' do
      expect(subject.to_sym).to be(:method_1)
    end
  end
  context 'when used as a key in a hash' do
    context 'accessing with different instances for the same method name' do
      it 'shares the same key in the hash with the other instance' do
        instance_1 = described_class.new(method_name)
        instance_2 = described_class.new(method_name)
        hash = { instance_1 => nil }
        expect(hash).to have_key(instance_2)
      end
    end
    it 'does not refer to the same key as the symbol of the method name' do
      hash = { subject => nil }
      expect(hash).not_to have_key(method_name)
    end
  end
end
