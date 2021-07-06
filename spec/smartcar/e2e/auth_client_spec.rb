# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar::AuthClient do
  subject { Smartcar::AuthClient.new(AuthHelper.auth_client_params) }

  describe '.exchange_code' do
    it 'should fetch all the tokens' do
      url = subject.get_auth_url(AuthHelper::SCOPE, { force_prompt: true })
      code = AuthHelper.run_auth_flow(url)
      token_hash = subject.exchange_code(code)
      expect(token_hash.keys.map(&:to_s)).to match_array(%w[token_type access_token refresh_token expires_at])
    end
  end

  describe '.exchange_refresh_token' do
    it 'should refresh and fetch all the tokens' do
      url = subject.get_auth_url(AuthHelper::SCOPE, { force_prompt: true })
      code = AuthHelper.run_auth_flow(url)
      old_token_hash = subject.exchange_code(code)
      new_token_hash = subject.exchange_refresh_token(old_token_hash[:refresh_token])
      expect(new_token_hash.keys.map(&:to_s)).to match_array(%w[token_type access_token refresh_token expires_at])
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
