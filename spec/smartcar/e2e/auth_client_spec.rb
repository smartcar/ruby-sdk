# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar::AuthClient do
  subject { Smartcar::AuthClient.new(AuthHelper.auth_client_params) }

  describe '.exchange_code' do
    it 'should fetch all the tokens' do
      current_time = Time.now
      url = subject.get_auth_url(AuthHelper::SCOPE, { force_prompt: true })
      code = AuthHelper.run_auth_flow(url)
      tokens = subject.exchange_code(code)
      expect(tokens.access_token.length).to eq(36)
      expect((Time.at(tokens.expires_at) - current_time) >= 7200).to be_truthy
      expect(tokens.refresh_token.length).to eq(36)
      expect(tokens.token_type).to eq('Bearer')
    end
  end

  describe '.exchange_refresh_token' do
    it 'should refresh and fetch all the tokens' do
      url = subject.get_auth_url(AuthHelper::SCOPE, { force_prompt: true })
      code = AuthHelper.run_auth_flow(url)
      old_tokens = subject.exchange_code(code)
      new_tokens = subject.exchange_refresh_token(old_tokens.refresh_token)
      expect(new_tokens.access_token.length).to eq(36)
      expect(new_tokens.access_token).not_to eq(old_tokens.access_token)
      expect(new_tokens.refresh_token.length).to eq(36)
      expect(new_tokens.token_type).to eq('Bearer')

      expect { subject.exchange_refresh_token(old_tokens.refresh_token) }.to(raise_error do |error|
        expect(error.type).to eq('invalid_grant')
        expect(error.message).to eq('invalid_grant: - Invalid or expired refresh token.')
        expect(error.request_id.length).to eq(36)
        expect(error.status_code).to eq(400)
      end)
    end
  end

  context 'expired?' do
    it 'should return boolean indicating if token is expired using expires_at' do
      expired_time = (Time.now - (60 * 60 * 24)).to_i
      valid_time = (Time.now + (60 * 60 * 24)).to_i
      expect(subject.expired?(expired_time)).to be_truthy
      expect(subject.expired?(valid_time)).to be_falsey
    end
  end
end
