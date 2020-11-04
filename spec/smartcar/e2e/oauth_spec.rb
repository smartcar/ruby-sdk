# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar::Oauth do
  subject { Smartcar::Oauth.new(AuthHelper.auth_client_params) }

  describe '.get_token' do
    it 'should fetch all the tokens' do
      url = subject.authorization_url
      code = AuthHelper.run_auth_flow(url)
      token_hash = subject.get_token(code)
      expect(token_hash.keys.map(&:to_s)).to match_array(%w[token_type access_token refresh_token expires_at])
    end
  end

  describe '.exchange_refresh_token' do
    it 'should refresh and fetch all the tokens' do
      url = subject.authorization_url
      code = AuthHelper.run_auth_flow(url)
      old_token_hash = subject.get_token(code)
      new_token_hash = subject.exchange_refresh_token(old_token_hash[:refresh_token])
      expect(new_token_hash.keys.map(&:to_s)).to match_array(%w[token_type access_token refresh_token expires_at])
    end
  end

  context 'expired?' do
    it 'should return boolean indicating if token is expired using expires_at' do
      expiredTime = (Time.now - (60*60*24)).to_i
      validTime = (Time.now + (60*60*24)).to_i
      expect(subject.expired?(expiredTime)).to be_truthy
      expect(subject.expired?(validTime)).to be_falsey
    end
  end
end
