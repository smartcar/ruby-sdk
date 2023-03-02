# frozen_string_literal: true

RSpec.describe Smartcar::AuthClient do
  subject do
    Smartcar::AuthClient.new({
                               redirect_uri: 'test_url',
                               client_id: 'SMARTCAR_CLIENT_ID',
                               client_secret: 'SMARTCAR_CLIENT_SECRET',
                               mode: 'test',
                             })
  end
  let(:obj) { double('dummy object for client') }

  before do
    allow(subject).to receive_message_chain(:connect_client, :auth_code).and_return(obj)
  end

  context 'constructor' do
    it 'check url of default constructor' do
      client = Smartcar::AuthClient.new({
                                          redirect_uri: 'test_url',
                                          client_id: 'SMARTCAR_CLIENT_ID',
                                          client_secret: 'SMARTCAR_CLIENT_SECRET'
                                        })
      expect(client.get_auth_url(%w[testing1 testing2], {})).to eq(
        'https://connect.smartcar.com/oauth/authorize?client_id=SMARTCAR_CLIENT_ID&mode=live&redirect_uri=test_url&response_type=code&scope=testing1+testing2'
      )
    end
    it 'check url of constructor with mode set to simulated' do
      client = Smartcar::AuthClient.new({
                                          redirect_uri: 'test_url',
                                          client_id: 'SMARTCAR_CLIENT_ID',
                                          client_secret: 'SMARTCAR_CLIENT_SECRET',
                                          mode: 'simulated'
                                        })
      expect(client.get_auth_url(%w[testing1 testing2], {})).to eq(
        'https://connect.smartcar.com/oauth/authorize?client_id=SMARTCAR_CLIENT_ID&mode=simulated&redirect_uri=test_url&response_type=code&scope=testing1+testing2'
      )
    end
    it 'check url of constructor with test_mode set to true' do
      client = Smartcar::AuthClient.new({
                                          redirect_uri: 'test_url',
                                          client_id: 'SMARTCAR_CLIENT_ID',
                                          client_secret: 'SMARTCAR_CLIENT_SECRET',
                                          test_mode: true
                                        })
      expect(client.get_auth_url(%w[testing1 testing2], {})).to eq(
        'https://connect.smartcar.com/oauth/authorize?client_id=SMARTCAR_CLIENT_ID&mode=test&redirect_uri=test_url&response_type=code&scope=testing1+testing2'
      )
    end
    it 'raises error if mode is invalid' do
      expect { Smartcar::AuthClient.new({ mode: 'invalid' }) }.to(raise_error do |error|
        expect(error.message).to eq(
          'The "mode" parameter MUST be one of the following: \'test\', \'live\', \'simulated\''
        )
      end)
    end
  end
  context 'authorization_url with single select vin' do
    it 'should call authorize_url from client.authcode' do
      expect(obj).to receive(:authorize_url).with({
                                                    redirect_uri: 'test_url',
                                                    scope: 'testing1 testing2',
                                                    mode: 'test',
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

  context 'authorization_url with single select enabled' do
    it 'should call authorize_url from client.authcode' do
      expect(obj).to receive(:authorize_url).with({
                                                    redirect_uri: 'test_url',
                                                    scope: 'testing1 testing2',
                                                    mode: 'test',
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
      allow(subject).to receive(:connect_client).and_call_original
    end
    it 'should create OAuth2::Client object' do
      expect(OAuth2::Client).to receive(:new)
      subject.send(:connect_client)
    end
  end
end
