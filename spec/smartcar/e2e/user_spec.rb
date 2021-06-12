# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar::User do
  subject { Smartcar::User }

  before(:context) do
    token_hash = AuthHelper.run_auth_flow_and_get_tokens
    @token = token_hash[:access_token]
  end

  describe '.user_id' do
    it 'should return the user id' do
      user_id = subject.user_id(token: @token)
      expect(user_id).not_to be_nil
    end
  end

  describe '.get' do
    it 'should return the user object' do
      user = subject.get(token: @token)
      expect(user.is_a?(subject)).to be_truthy
      expect(user.id).not_to be_nil
    end
  end
end
