# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar::Oauth do
  subject { Smartcar::Oauth }

  describe '.get_token' do
    it 'should fetch all the tokens' do
      url = subject.authorization_url(AuthHelper.auth_client_params)
      code = AuthHelper.run_auth_flow(url)
      token_hash = subject.get_token(code)
      expect(token_hash.keys.map(&:to_s)).to match_array(%w[token_type access_token refresh_token expires_at])
    end
  end

  describe '.refresh_token' do
    it 'should refresh and fetch all the tokens' do
      url = subject.authorization_url(AuthHelper.auth_client_params)
      code = AuthHelper.run_auth_flow(url)
      old_token_hash = subject.get_token(code)
      new_token_hash = subject.refresh_token(old_token_hash)
      expect(new_token_hash.keys.map(&:to_s)).to match_array(%w[token_type access_token refresh_token expires_at])
    end
  end
end
