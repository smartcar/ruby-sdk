# frozen_string_literal: true

class Temp
  include Smartcar::Utils
end
RSpec.describe Smartcar::Utils do
  subject do
    Temp.new
  end

  describe 'get_config' do
    before do
      allow(subject).to receive(:get_config).and_call_original
    end
    context 'If the config is present' do
      before do
        stub_const('ENV', { 'test' => 'result' })
      end
      it 'should get the requested config' do
        expect(subject.send(:get_config, 'test')).to eq('result')
      end
    end
    context 'If the config is not present' do
      before do
        stub_const('ENV', {})
      end
      it 'should get raise ConfigNotFound' do
        expect do
          subject.send(:get_config, 'test')
        end.to raise_error(Smartcar::ConfigNotFound, 'Environment variable test not found !')
      end
    end

    context 'If the config is not present' do
      before do
        stub_const('ENV', { 'MODE' => 'test', 'E2E_PIZZA' => 'not_pasta' })
      end
      it 'should append E2E before looking up the environment' do
        expect(subject.send(:get_config, 'PIZZA')).to eq('not_pasta')
      end
    end
  end
end
