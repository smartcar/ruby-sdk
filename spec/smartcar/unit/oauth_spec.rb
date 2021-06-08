# frozen_string_literal: true

RSpec.describe Smartcar::Oauth do
  subject do
    Smartcar::Oauth.new({
                          redirect_uri: 'test_url',
                          client_id: 'client_id',
                          client_secret: 'client_secret',
                          test_mode: true,
                          scope: ['testing']
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
                                                    scope: 'testing',
                                                    approval_prompt: Smartcar::AUTO,
                                                    mode: Smartcar::TEST,
                                                    response_type: Smartcar::CODE,
                                                    flags: 'country:DE',
                                                    state: 'blah',
                                                    make: 'blah',
                                                    single_select: true,
                                                    single_select_vin: 'vin'
                                                  }).and_return('result')
      expect(subject.authorization_url(
               {
                 flags: ['country:DE'],
                 state: 'blah',
                 make: 'blah',
                 single_select: { vin: 'vin' }
               }
             )).to eq 'result'
    end
  end

  context 'get_token' do
    it 'should call get_token from client.authcode' do
      expect(obj).to receive(:get_token)
        .with('auth_code', { redirect_uri: 'test_url' })
        .and_return(double('obj', to_hash: { result: 'result' }))
      expect(subject.get_token('auth_code')).to eq({ result: 'result' })
    end
  end

  context 'exchange_refresh_token' do
    it 'should create new OAuth2::AccessToken object, refresh and return new hash' do
      token_hash = { refresh_token: 'refresh_token' }
      double_object = double('obj')
      allow(subject).to receive_message_chain(:client).and_return(obj)
      expect(OAuth2::AccessToken).to receive(:from_hash).with(obj, token_hash).and_return(double_object)
      expect(double_object).to receive(:refresh!).and_return(double_object)
      expect(double_object).to receive(:to_hash)
      subject.exchange_refresh_token(token_hash[:refresh_token])
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
