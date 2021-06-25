# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar do
  subject { Smartcar }
  before(:context) do
    token_hash = AuthHelper.run_auth_flow_and_get_tokens
    @token = token_hash[:access_token]
  end

  describe '.get_compatibility' do
    it 'should respond if vehicle is compatible for given scopes' do
      tesla_vin = '5YJXCDE22HF068739'
      audi_vin = 'WAUAFAFL1GN014882'
      scopes = %w[read_odometer read_location]

      result = subject.get_compatibility(vin: tesla_vin, scope: scopes)

      expect(result.compatible).to be_truthy

      result = subject.get_compatibility(vin: audi_vin, scope: scopes)
      expect(result.compatible).to be_falsey
    end

    it 'should respond if country is specified and vehicle is compatible for given scopes' do
      tesla_vin = '5YJXCDE22HF068739'
      audi_vin = 'WAUAFAFL1GN014882'
      scopes = %w[read_odometer read_location]
      country = 'US'

      result = subject.get_compatibility(vin: tesla_vin, scope: scopes, country: country)
      expect(result.compatible).to be_truthy

      result = subject.get_compatibility(vin: audi_vin, scope: scopes, country: country)
      expect(result.compatible).to be_falsey
    end
  end

  describe '.get_vehicles' do
    it 'should return all vehicle ids associated with the account' do
      response = subject.get_vehicles(token: @token)
      expect(response.vehicles.is_a?(Array)).to be_truthy
      response.vehicles.each { |vehicle_id| expect(vehicle_id.length).to be(36) }
      expect(response.paging.is_a?(OpenStruct)).to be_truthy
      expect(response.paging.offset).to be(0)
      expect(response.paging.count).to be(response.vehicles.length)
      expect(response.meta.request_id.length).to be(36)
    end
  end

  describe '.get_user' do
    it 'should return the user object' do
      user = subject.get_user(token: @token)
      expect(user.is_a?(OpenStruct)).to be_truthy
      expect(user.id.length).to be(36)
      expect(user.meta.request_id.length).to be(36)
    end
  end
end
