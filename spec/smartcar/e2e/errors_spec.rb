# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar::Vehicle do
  subject { Smartcar::Vehicle }

  def get_token(email)
    client = Smartcar::Oauth.new(AuthHelper.auth_client_params)
    url = client.authorization_url
    token_hash = client.get_token(AuthHelper.run_auth_flow(url, email))
    token_hash[:access_token]
  end

  describe 'error' do
    context 'with V1 requests' do
      it 'should raise InvalidParameterValue error' do
        expected_keys = ["error", "message", "code", "statusCode", "requestId"]
        token = get_token('smartcar@vs-000.vehicle-state-error.com')
        vehicle_ids =  Smartcar::Vehicle.all_vehicle_ids(token: token)
        vehicle = subject.new(token: token, id: vehicle_ids.first)
        expect { vehicle.odometer }.to raise_error { |error|
          error_body = JSON.parse(error.message.split("error - ")[1])
          expect(error_body.keys).to match_array expected_keys
          expect(error_body["error"]).to eq("vehicle_state_error")
        }
      end
    end

    # TODO : update this test later when we can make v2 errors request
    # context 'with V2 requests' do
    #   it 'should raise InvalidParameterValue error' do
    #     token = get_token('smartcar@VS-000.vehicle-state-error.com')
    #     vehicle_ids =  Smartcar::Vehicle.all_vehicle_ids(token: token)
    #     vehicle = subject.new(token: token, id: vehicle_ids.first, version: 'v2.0')
    #     expect { vehicle.odometer }.to raise_error { |error|
    #       error_body = JSON.parse(error.message.split("error - ")[1])
    #       expect(error_body["error"]).to eq("permission_error")
    #     }
    #   end
    # end
  end
end
