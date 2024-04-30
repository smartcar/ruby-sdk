# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe SmartcarError do
  subject { Smartcar::Vehicle }

  def get_vehicle_object(email = nil)
    token_hash = AuthHelper.run_auth_flow_and_get_tokens(email, nil, ['read_odometer'])
    vehicle_ids = Smartcar.get_vehicles(token: token_hash[:access_token])
    subject.new(token: token_hash[:access_token], id: vehicle_ids.vehicles.first)
  end

  describe 'error' do
    context 'with V1 requests' do
      before(:context) do
        Smartcar.set_api_version('1.0')
      end

      after(:context) do
        Smartcar.set_api_version('2.0')
      end
      it 'should raise SmartcarError error' do
        vehicle = get_vehicle_object('smartcar@vs-000.vehicle-state-error.com')
        expect { vehicle.odometer }.to(raise_error do |error|
          expect(error.type).to eq('vehicle_state_error')
          expect(error.message).to eq('vehicle_state_error:VS_000 - Vehicle state cannot be determined.')
          expect(error.code).to eq('VS_000')
          expect(error.status_code).to eq(409)
        end)
      end

      it 'should raise InvalidParameterValue error' do
        vehicle = get_vehicle_object
        expect { vehicle.location }.to(raise_error do |error|
          expect(error.type).to eq('permission_error')
          expect(error.message).to eq('permission_error: - Insufficient permissions to access requested resource.')
          expect(error.code).to be_nil
          expect(error.status_code).to eq(403)
        end)
      end
    end

    describe 'v2 errors' do
      context 'with null code' do
        it 'should have empty code' do
          vehicle = get_vehicle_object
          expected_description = "Your application has insufficient permissions to access the requested resource. \
Please prompt the user to re-authenticate using Smartcar Connect."
          expect { vehicle.location }.to(raise_error do |error|
            expect(error.status_code).to eq(403)
            expect(error.type).to eq('PERMISSION')
            expect(error.code).to be_nil
            expect(error.description).to eq(expected_description)
            expect(error.doc_url).to eq('https://smartcar.com/docs/errors/api-errors/permission-errors#null')
            expect(error.resolution.type).to eq('REAUTHENTICATE')
            expect(error.message).to eq("PERMISSION: - #{expected_description}")
          end)
        end
      end
    end
  end
end

  #  Note: we skip the following 2 tests because the account associated with them
  #  began throwing Smartcar Authentication errors. At this time, we have not diagnosed
  #  exactly why this is happening, so we skip for now to move projects forward.

  # context 'with resolution string' do
  #   it 'should convert the resolution string to object and fill the value in type' do
  #     vehicle = get_vehicle_object('VEHICLE_STATE.UNKNOWN@smartcar.com')
  #     expected_description = 'The vehicle was unable to perform your request due to an unknown issue.'
  #     expect { vehicle.odometer }.to(raise_error do |error|
  #       expect(error.status_code).to eq(409)
  #       expect(error.type).to eq('VEHICLE_STATE')
  #       expect(error.code).to eq('UNKNOWN')
  #       expect(error.description).to eq(expected_description)
  #       expect(error.doc_url).to eq('https://smartcar.com/docs/errors/api-errors/vehicle-state-errors#unknown')
  #       expect(error.resolution.type).to eq('RETRY_LATER')
  #       expect(error.message).to eq("VEHICLE_STATE:UNKNOWN - #{expected_description}")
  #     end)
  #   end
  # end

  # context 'with null resolution' do
  #   it 'should have empty resolution' do
  #     vehicle = get_vehicle_object('CONNECTED_SERVICES_ACCOUNT.VEHICLE_MISSING@smartcar.com')
  #     expected_description = "This vehicle is no longer associated with the user's connected services account. "\
  #     "Please prompt the user to re-add the vehicle to their account."
  #     expect { vehicle.odometer }.to(raise_error do |error|
  #       expect(error.status_code).to eq(400)
  #       expect(error.type).to eq('CONNECTED_SERVICES_ACCOUNT')
  #       expect(error.code).to eq('VEHICLE_MISSING')
  #       expect(error.description).to eq(expected_description)
  #       expect(error.doc_url).to eq('https://smartcar.com/docs/errors/api-errors/connected-services-account-errors#vehicle-missing')
  #       expect(error.resolution.type).to be_nil
  #       expect(error.message).to eq("CONNECTED_SERVICES_ACCOUNT:VEHICLE_MISSING - #{expected_description}")
  #     end)
  #   end
  # end

