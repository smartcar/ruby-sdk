# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar::AuthClient do
  subject do
    Smartcar::AuthClient.new(
      AuthHelper.auth_client_params.merge(
        {
          client_id: 'client_id',
          client_secret: 'client_secret'
        }
      )
    )
  end
  before do
    @auth_origin = ENV.fetch('SMARTCAR_AUTH_ORIGIN', nil)
    ENV['SMARTCAR_AUTH_ORIGIN'] = 'https://pizza.pasta.pi'
    WebMock.disable_net_connect!
  end

  after do
    WebMock.allow_net_connect!
    ENV['SMARTCAR_AUTH_ORIGIN'] = @auth_origin
  end

  def token_request_body(grant_type = 'authorization_code')
    params = {
      client_id: 'client_id',
      client_secret: 'client_secret',
      grant_type: grant_type
    }
    return params.merge(refresh_token: 'refresh_token') unless grant_type == 'authorization_code'

    params.merge(code: 'auth_code', redirect_uri: 'https://example.com/auth')
  end

  def token_response
    {
      status: 200,
      headers: { 'content-type' => 'application/json; charset=utf-8' },
      body: {
        access_token: 'pizza_token',
        token_type: 'Bearer',
        expires_in: 7200,
        refresh_token: 'pasta_token'
      }.to_json
    }
  end

  context 'constructor' do
    it 'raises error if redirect URL is not present' do
      redirect_url = ENV.fetch('E2E_SMARTCAR_REDIRECT_URI', nil)
      ENV.delete('E2E_SMARTCAR_REDIRECT_URI')

      expect { Smartcar::AuthClient.new({}) }.to(raise_error do |error|
        expect(error.message).to eq('Environment variable E2E_SMARTCAR_REDIRECT_URI not found !')
      end)
      ENV['E2E_SMARTCAR_REDIRECT_URI'] = redirect_url
    end

    it 'raises error if client ID is not present' do
      client_id = ENV.fetch('E2E_SMARTCAR_CLIENT_ID', nil)
      ENV.delete('E2E_SMARTCAR_CLIENT_ID')

      expect { Smartcar::AuthClient.new({}) }.to(raise_error do |error|
        expect(error.message).to eq('Environment variable E2E_SMARTCAR_CLIENT_ID not found !')
      end)
      ENV['E2E_SMARTCAR_CLIENT_ID'] = client_id
    end

    it 'raises error if client secret is not present' do
      client_secret = ENV.fetch('E2E_SMARTCAR_CLIENT_SECRET', nil)
      ENV.delete('E2E_SMARTCAR_CLIENT_SECRET')

      expect { Smartcar::AuthClient.new({}) }.to(raise_error do |error|
        expect(error.message).to eq('Environment variable E2E_SMARTCAR_CLIENT_SECRET not found !')
      end)
      ENV['E2E_SMARTCAR_CLIENT_SECRET'] = client_secret
    end
  end

  context 'get_token' do
    it 'should call get_token from client.authcode using given host with flags' do
      stub_request(:post, 'https://pizza.pasta.pi/oauth/token?flags=pizza:pasta')
        .with(body: token_request_body)
        .to_return(token_response)
      response = subject.exchange_code('auth_code', { flags: { pizza: 'pasta' } })
      expect(response[:access_token]).to eq('pizza_token')
      expect(response[:refresh_token]).to eq('pasta_token')
    end

    it 'should call get_token from client.authcode using given host' do
      stub_request(:post, 'https://pizza.pasta.pi/oauth/token')
        .with(body: token_request_body)
        .to_return(token_response)
      response = subject.exchange_code('auth_code')
      expect(response[:access_token]).to eq('pizza_token')
      expect(response[:refresh_token]).to eq('pasta_token')
    end
  end

  context 'exchange_refresh_token' do
    it 'should call refresh token endpoint using given host with flags' do
      stub_request(:post, 'https://pizza.pasta.pi/oauth/token')
        .with(body: token_request_body('refresh_token'))
        .to_return(token_response)
      response = subject.exchange_refresh_token('refresh_token')
      expect(response[:access_token]).to eq('pizza_token')
      expect(response[:refresh_token]).to eq('pasta_token')
    end
  end
end
