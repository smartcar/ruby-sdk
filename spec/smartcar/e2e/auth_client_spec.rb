# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar::AuthClient do
  describe 'authentication flow tests' do
    before(:all) do
      @auth_client = Smartcar::AuthClient.new(AuthHelper.auth_client_params)
      @current_time = Time.now
      auth_url = @auth_client.get_auth_url(AuthHelper::SCOPE, { force_prompt: true })
      @code = AuthHelper.run_auth_flow(auth_url)
      @initial_tokens = @auth_client.exchange_code(@code)
      @refreshed_tokens = @auth_client.exchange_refresh_token(@initial_tokens.refresh_token)
    end

    it 'correctly exchanges authorization code for tokens' do
      expect(@initial_tokens.access_token.length).to eq(36)
      expect((Time.at(@initial_tokens.expires_at) - @current_time) >= 7200).to be_truthy
      expect(@initial_tokens.refresh_token.length).to eq(36)
      expect(@initial_tokens.token_type).to eq('Bearer')
    end

    it 'correctly refreshes tokens using refresh_token' do
      expect(@refreshed_tokens.access_token.length).to eq(36)
      expect(@refreshed_tokens.access_token).not_to eq(@initial_tokens.access_token)
      expect(@refreshed_tokens.refresh_token.length).to eq(36)
      expect(@refreshed_tokens.token_type).to eq('Bearer')
    end

    it 'correctly identifies expired and valid tokens' do
      expired_time = (Time.now - (60 * 60 * 24)).to_i
      valid_time = (Time.now + (60 * 60 * 24)).to_i
      expect(@auth_client.expired?(expired_time)).to be_truthy
      expect(@auth_client.expired?(valid_time)).to be_falsey
    end
  end
end
