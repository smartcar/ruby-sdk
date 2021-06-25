# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe SmartcarError do
  subject { Smartcar::Vehicle }

  def get_token(email)
    token_hash = AuthHelper.run_auth_flow_and_get_tokens(email)
    token_hash[:access_token]
  end

  describe 'error' do
    context 'with V1 requests' do
      before(:context) do
        Smartcar.set_api_version('1.0')
      end

      after(:context) do
        Smartcar.set_api_version('2.0')
      end
      it 'should raise InvalidParameterValue error' do
        token = get_token('smartcar@vs-000.vehicle-state-error.com')
        vehicle_ids = Smartcar.get_vehicles(token: token)
        vehicle = subject.new(token: token, id: vehicle_ids.vehicles.first)
        expect { vehicle.odometer }.to(raise_error do |error|
          expect(error.error).to eq('vehicle_state_error')
          expect(error.message).to eq('Vehicle state cannot be determined.')
          expect(error.code).to eq('VS_000')
          expect(error.status_code).to eq(409)
        end)
      end
    end

    context 'with V2 requests' do
      it 'should raise InvalidParameterValue error' do
        token = get_token('VEHICLE_STATE.UNKNOWN@smartcar.com')
        vehicle_ids = Smartcar.get_vehicles(token: token)
        vehicle = subject.new(token: token, id: vehicle_ids.vehicles.first)
        expected_description = 'The vehicle was unable to perform your request due to an unknown issue.'
        expect { vehicle.odometer }.to(raise_error do |error|
          expect(error.status_code).to eq(409)
          expect(error.type).to eq('VEHICLE_STATE')
          expect(error.code).to eq('UNKNOWN')
          expect(error.description).to eq(expected_description)
          expect(error.doc_url).to eq('https://smartcar.com/docs/errors/v2.0/vehicle-state/#unknown')
          expect(error.resolution).to eq('RETRY_LATER')
          expect(error.message).to eq("VEHICLE_STATE:UNKNOWN - #{expected_description}")
        end)
      end
    end
  end
end
