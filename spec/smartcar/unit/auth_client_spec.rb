# frozen_string_literal: true

RSpec.describe Smartcar::AuthClient do
  subject do
    Smartcar::AuthClient.new({
                               redirect_uri: 'test_url',
                               client_id: 'SMARTCAR_CLIENT_ID',
                               client_secret: 'SMARTCAR_CLIENT_SECRET',
                               test_mode: true
                             })
  end
  let(:obj) { double('dummy object for client') }

  before do
    allow(subject).to receive_message_chain(:client, :auth_code).and_return(obj)
  end

  context 'authorization_url' do
    it 'should call authorize_url from client.authcode' do
      expect(obj).to receive(:authorize_url).with({
                                                    redirect_uri: 'test_url',
                                                    scope: 'testing1 testing2',
                                                    approval_prompt: Smartcar::AUTO,
                                                    mode: Smartcar::TEST,
                                                    response_type: Smartcar::CODE,
                                                    flags: 'country:DE',
                                                    state: 'blah',
                                                    make: 'blah',
                                                    single_select: true,
                                                    single_select_vin: 'vin'
                                                  }).and_return('result')
      expect(subject.get_auth_url(%w[testing1 testing2],
                                  {
                                    flags: { country: 'DE' },
                                    state: 'blah',
                                    make: 'blah',
                                    single_select: { vin: 'vin' }
                                  })).to eq 'result'
    end
  end

  context 'client' do
    before do
      allow(subject).to receive(:client).and_call_original
    end
    it 'should create OAuth2::Client object' do
      expect(OAuth2::Client).to receive(:new)
      subject.send(:client)
    end
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
  end
end
