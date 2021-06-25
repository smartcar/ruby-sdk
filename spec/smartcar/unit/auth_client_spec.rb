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

  context 'authorization_url with single select vin' do
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
                                    make_bypass: 'blah',
                                    single_select: { vin: 'vin' }
                                  })).to eq 'result'
    end
  end

  context 'authorization_url with single select vin' do
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
                                                    single_select: true
                                                  }).and_return('result')
      expect(subject.get_auth_url(%w[testing1 testing2],
                                  {
                                    flags: { country: 'DE' },
                                    state: 'blah',
                                    make_bypass: 'blah',
                                    single_select: { enabled: true }
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
end
