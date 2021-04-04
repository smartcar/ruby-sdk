# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar::Vehicle do
  subject { Smartcar::Vehicle }

  def get_token(email)
    client = Smartcar::Oauth.new(AuthHelper.auth_client_params)
    url = client.authorization_url({ force_prompt: true })
    token_hash = client.get_token(AuthHelper.run_auth_flow(url, email))
    token_hash[:access_token]
  end

  describe 'error' do
    context 'with V1 requests' do
      it 'should raise InvalidParameterValue error' do
        expected_keys = %w[error message code statusCode requestId]
        token = get_token('smartcar@vs-000.vehicle-state-error.com')
        vehicle_ids = Smartcar::Vehicle.all_vehicle_ids(token: token)
        vehicle = subject.new(token: token, id: vehicle_ids.first)
        expect { vehicle.odometer }.to(raise_error do |error|
          error_body = JSON.parse(error.message.split('error - ')[1])
          expect(error_body.keys).to match_array expected_keys
          expect(error_body['error']).to eq('vehicle_state_error')
        end)
      end
    end

    context 'with V2 requests' do
      before(:context) do
        Smartcar.set_api_version('2.0')
      end

      after(:context) do
        Smartcar.set_api_version('1.0')
      end

      it 'should raise InvalidParameterValue error' do
        token = get_token('VEHICLE_STATE.UNKNOWN@smartcar.com')
        vehicle_ids = Smartcar::Vehicle.all_vehicle_ids(token: token)
        vehicle = subject.new(token: token, id: vehicle_ids.first)
        expected_description = 'The vehicle was unable to perform your request due to an unknown issue.'
        expect { vehicle.odometer }.to(raise_error do |error|
          error_body = JSON.parse(error.message.split('error - ')[1])
          expect(error_body['statusCode']).to eq(409)
          expect(error_body['type']).to eq('VEHICLE_STATE')
          expect(error_body['code']).to eq('UNKNOWN')
          expect(error_body['description']).to eq(expected_description)
          expect(error_body['docURL']).to eq('https://smartcar.com/docs/errors/v2.0/vehicle-state/#unknown')
          expect(error_body['resolution']).to eq('RETRY_LATER')
        end)
      end
    end
  end
end
