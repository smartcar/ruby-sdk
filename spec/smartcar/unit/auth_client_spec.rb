# frozen_string_literal: true

RSpec.describe Smartcar::AuthClient do
  subject do
    Smartcar::AuthClient.new({
                               redirect_uri: 'test_url',
                               client_id: 'SMARTCAR_CLIENT_ID',
                               client_secret: 'SMARTCAR_CLIENT_SECRET',
                               mode: 'test'
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

  context 'authorization_url with user' do
    it 'should call authorize_url from client.authcode' do
      expect(obj).to receive(:authorize_url).with({
                                                    redirect_uri: 'test_url',
                                                    scope: 'testing1 testing2',
                                                    mode: 'test',
                                                    response_type: Smartcar::CODE,
                                                    flags: 'country:DE',
                                                    state: 'blah',
                                                    make: 'blah',
                                                    user: 'test-user-id'
                                                  }).and_return('result')
      expect(subject.get_auth_url(%w[testing1 testing2],
                                  {
                                    flags: { country: 'DE' },
                                    state: 'blah',
                                    make_bypass: 'blah',
                                    user: 'test-user-id'
                                  })).to eq 'result'
    end
  end

  context 'connect_client' do
    before do
      allow(subject).to receive(:connect_client).and_call_original
    end
    it 'should create OAuth2::Client object' do
      expect(OAuth2::Client).to receive(:new)
      subject.send(:connect_client)
    end
  end
  context 'it should check the base url for connect_client and auth_client' do
    it 'verifies the auth_url' do
      client = Smartcar::AuthClient.new({
                                          redirect_uri: 'test_url',
                                          client_id: 'SMARTCAR_CLIENT_ID',
                                          client_secret: 'SMARTCAR_CLIENT_SECRET'
                                        })
      url = client.instance_variable_get(:@auth_origin)
      expect(url).to eq('https://auth.smartcar.com')
    end
    it 'verifies the connect_url' do
      client = Smartcar::AuthClient.new({
                                          redirect_uri: 'test_url',
                                          client_id: 'SMARTCAR_CLIENT_ID',
                                          client_secret: 'SMARTCAR_CLIENT_SECRET'
                                        })
      url = client.instance_variable_get(:@connect_origin)
      expect(url).to eq('https://connect.smartcar.com')
    end
  end
  context 'auth_client' do
    before do
      allow(subject).to receive(:auth_client).and_call_original
    end
    it 'should create OAuth2::Client object' do
      expect(OAuth2::Client).to receive(:new)
      subject.send(:auth_client)
    end
  end

  context 'optional parameters' do
    let(:obj_without_redirect) { double('dummy object without redirect_uri') }

    it 'should work without scope parameter' do
      client = Smartcar::AuthClient.new({
                                          redirect_uri: 'test_url',
                                          client_id: 'SMARTCAR_CLIENT_ID',
                                          client_secret: 'SMARTCAR_CLIENT_SECRET',
                                          mode: 'test'
                                        })
      allow(client).to receive_message_chain(:connect_client, :auth_code).and_return(obj)

      expect(obj).to receive(:authorize_url) do |params|
        expect(params[:response_type]).to eq(Smartcar::CODE)
        expect(params[:mode]).to eq('test')
        expect(params[:redirect_uri]).to eq('test_url')
        expect(params[:state]).to eq('test_state')
        expect(params).not_to have_key(:scope)
        'result'
      end

      expect(client.get_auth_url({ state: 'test_state' })).to eq 'result'
    end

    it 'should work without redirect_uri parameter' do
      # Temporarily remove the E2E_SMARTCAR_REDIRECT_URI env var to test without redirect_uri
      original_redirect = ENV['E2E_SMARTCAR_REDIRECT_URI']
      ENV.delete('E2E_SMARTCAR_REDIRECT_URI')

      client = Smartcar::AuthClient.new({
                                          client_id: 'SMARTCAR_CLIENT_ID',
                                          client_secret: 'SMARTCAR_CLIENT_SECRET',
                                          mode: 'test'
                                        })

      expect(client.redirect_uri).to be_nil

      allow(client).to receive_message_chain(:connect_client, :auth_code).and_return(obj_without_redirect)

      expect(obj_without_redirect).to receive(:authorize_url) do |params|
        expect(params[:response_type]).to eq(Smartcar::CODE)
        expect(params[:mode]).to eq('test')
        expect(params[:scope]).to eq('read_odometer')
        expect(params).not_to have_key(:redirect_uri)
        'result'
      end

      expect(client.get_auth_url(['read_odometer'], {})).to eq 'result'

      # Restore the environment variable
      ENV['E2E_SMARTCAR_REDIRECT_URI'] = original_redirect if original_redirect
    end

    it 'should work without both scope and redirect_uri' do
      # Temporarily remove the E2E_SMARTCAR_REDIRECT_URI env var to test without redirect_uri
      original_redirect = ENV['E2E_SMARTCAR_REDIRECT_URI']
      ENV.delete('E2E_SMARTCAR_REDIRECT_URI')

      client = Smartcar::AuthClient.new({
                                          client_id: 'SMARTCAR_CLIENT_ID',
                                          client_secret: 'SMARTCAR_CLIENT_SECRET',
                                          mode: 'test'
                                        })

      expect(client.redirect_uri).to be_nil

      allow(client).to receive_message_chain(:connect_client, :auth_code).and_return(obj_without_redirect)

      expect(obj_without_redirect).to receive(:authorize_url) do |params|
        expect(params[:response_type]).to eq(Smartcar::CODE)
        expect(params[:mode]).to eq('test')
        expect(params[:state]).to eq('test_state')
        expect(params).not_to have_key(:scope)
        expect(params).not_to have_key(:redirect_uri)
        'result'
      end

      expect(client.get_auth_url({ state: 'test_state' })).to eq 'result'

      # Restore the environment variable
      ENV['E2E_SMARTCAR_REDIRECT_URI'] = original_redirect if original_redirect
    end
  end
end
