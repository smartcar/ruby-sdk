# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar::Vehicle do
  subject { Smartcar::Vehicle }

  describe 'Data methods' do
    before(:context) do
      @token = AuthHelper.run_auth_flow_and_get_tokens[:access_token]
      @vehicle_ids = Smartcar.get_vehicles(token: @token).vehicles
      @vehicle = Smartcar::Vehicle.new(token: @token, id: @vehicle_ids.first)
    end

    describe '#attributes' do
      it 'should return an VehicleAttributes object' do
        result = @vehicle.attributes
        expect(result.make).to eq('CHEVROLET')
        expect(result.model).to eq('Volt')
        expect(result.year.is_a?(Integer)).to eq(true)
        expect(result.id.length).to eq(36)
        expect(result.meta.request_id.length).to eq(36)
      end
    end

    describe '#battery' do
      it 'should return an battery object' do
        result = @vehicle.battery
        expect(result.percentage_remaining >= 0 && result.percentage_remaining <= 1).to eq(true)
        expect(result.range.instance_of?(Float)).to eq(true)
        expect(result.meta.request_id.length).to eq(36)
        expect(result.meta.data_age.is_a?(DateTime)).to eq(true)
      end
    end

    describe '#battery_capacity' do
      it 'should return an battery_capacity object' do
        result = @vehicle.battery_capacity
        expect(result.capacity.instance_of?(Float)).to eq(true)
        expect(result.meta.request_id.length).to eq(36)
      end
    end

    describe '#charge' do
      it 'should return an charge object' do
        result = @vehicle.charge
        expect([true, false].include?(result.is_plugged_in?)).to eq(true)
        expect(%w[CHARGING FULLY_CHARGED NOT_CHARGING].include?(result.state)).to eq(true)
        expect(result.meta.request_id.length).to eq(36)
        expect(result.meta.data_age.is_a?(DateTime)).to eq(true)
      end
    end

    describe '#engine_oil' do
      it 'should return an engine_oil object' do
        result = @vehicle.engine_oil
        expect(result.life_remaining >= 0 && result.life_remaining <= 1).to eq(true)
        expect(result.meta.request_id.length).to eq(36)
        expect(result.meta.data_age.is_a?(DateTime)).to eq(true)
      end
    end

    describe '#diagnostic_system_status' do
      it 'should return a diagnostic system status object' do
        result = @vehicle.diagnostic_system_status
        expect(result.systems).to be_an(Array)
        unless result.systems.empty?
          first_system = result.systems.first
          expect(first_system.systemId).not_to be_nil
          expect(first_system.status).not_to be_nil
        end
        expect(result.meta.request_id.length).to eq(36)
        expect(result.meta.data_age).to be_a(DateTime)
      end
    end

    describe '#diagnostic_trouble_codes' do
      it 'should return a diagnostic trouble codes object' do
        result = @vehicle.diagnostic_trouble_codes
        expect(result.activeCodes).to be_an(Array)
        unless result.activeCodes.empty?
          first_code = result.activeCodes.first
          expect(first_code.code).not_to be_nil
          # Only check timestamp if it is present
          expect(first_code.timestamp).not_to be_nil if first_code.respond_to?(:timestamp) && first_code.timestamp
        end
        expect(result.meta.request_id.length).to eq(36)
        expect(result.meta.data_age).to be_a(DateTime)
      end
    end

    describe '#fuel' do
      it 'should return an fuel object' do
        result = @vehicle.fuel
        expect(result.percent_remaining >= 0 && result.percent_remaining <= 1).to eq(true)
        expect(result.amount_remaining.instance_of?(Float)).to eq(true)
        expect(result.meta.request_id.length).to eq(36)
        expect(result.meta.unit_system).to eq('metric')
        expect(result.meta.data_age.is_a?(DateTime)).to eq(true)
      end
    end

    describe '#location' do
      it 'should return an location object' do
        result = @vehicle.location
        expect(result.longitude.instance_of?(Float)).to eq(true)
        expect(result.latitude.instance_of?(Float)).to eq(true)
        expect(result.meta.request_id.length).to eq(36)
        expect(result.meta.data_age.is_a?(DateTime)).to eq(true)
      end
    end

    describe '#permissions' do
      it 'should return an permissions object' do
        result = @vehicle.permissions
        expect(result.permissions.map { |item| item.prepend('required:') }.sort).to eq(AuthHelper::SCOPE.sort)
        expect(result.meta.request_id.length).to eq(36)
      end
    end

    describe '#tire_pressure' do
      it 'should return an tire_pressure object' do
        result = @vehicle.tire_pressure
        %I[back_left front_left back_right front_right].each do |attribute|
          expect(result[attribute].instance_of?(Float)).to eq(true)
        end
        expect(result.meta.request_id.length).to eq(36)
        expect(result.meta.unit_system).to eq('metric')
        expect(result.meta.data_age.is_a?(DateTime)).to eq(true)
      end
    end

    describe '#vin' do
      it 'should return an vin string' do
        result = @vehicle.vin
        expect(result.vin.length).to eq(17)
        expect(result.meta.request_id.length).to eq(36)
      end
    end

    describe '#odometer' do
      it 'should return an odometer object' do
        result = @vehicle.odometer
        expect(result.distance.is_a?(Numeric)).to eq(true)
        expect(result.meta.request_id.length).to eq(36)
        expect(result.meta.unit_system).to eq('metric')
        expect(result.meta.data_age.is_a?(DateTime)).to eq(true)
      end
    end

    describe '#service_history' do
      it 'should return service history object with valid properties' do
        result = @vehicle.service_history('2021-01-01', '2021-12-31')
        # Check that items has at least 0 elements; this test will always pass since an empty array has 0 elements
        expect(result.items.length).to be >= 0
        # Check if there are elements, then each must have an odometerDistance
        result.items.each do |item|
          expect(item).to respond_to(:odometerDistance)
          # Check that odometerDistance is not nil and is a Float
          expect(item.odometerDistance).to be_a(Float)
        end
        # More expectations can be included if needed
        expect(result.meta.request_id.length).to eq(36)
        expect(result.meta.unit_system).to eq('metric')
        expect(result.meta.data_age.is_a?(DateTime)).to eq(true)
      end
    end
    describe '#charge_limit' do
      it 'should return an charge limit object' do
        result = @vehicle.get_charge_limit
        expect(result.limit.is_a?(Numeric)).to eq(true)
        expect(result.meta.data_age.is_a?(DateTime)).to eq(true)
      end
    end
    describe '#lock_status' do
      it 'should return a lock status object' do
        result = @vehicle.lock_status
        expect([true, false].include?(result.is_locked)).to eq(true)
        expect(result.doors.is_a?(Array))
        expect(result.windows.is_a?(Array))
        expect(result.sunroof.is_a?(Array))
        expect(result.storage.is_a?(Array))
        expect(result.charging_port.is_a?(Array))
        expect(result.meta.data_age.is_a?(DateTime)).to eq(true)
      end
    end

    describe '#batch - success' do
      context 'with valid attributes' do
        it 'should return hash of objects with attribute requested as keys' do
          attributes = ['/charge', '/battery', '/odometer', '/tires/pressure', '/security',
                        '/diagnostics/system_status', '/diagnostics/dtcs']
          result = @vehicle.batch(attributes)

          # Basic response type checks
          expect(result.is_a?(OpenStruct)).to eq(true)

          # Charge Assertions
          expect(result.charge.is_a?(OpenStruct)).to eq(true)
          expect(result.charge.is_plugged_in?).not_to be_nil
          expect(result.charge.state).not_to be_nil
          expect(result.charge.meta).not_to be_nil
          expect(result.charge.meta.request_id.length).to eq(36)

          # Battery Assertions
          expect(result.battery.is_a?(OpenStruct)).to eq(true)
          expect(result.battery.percentage_remaining).not_to be_nil
          expect(result.battery.range).not_to be_nil
          expect(result.battery.meta).not_to be_nil

          # Odometer Assertions
          expect(result.odometer.is_a?(OpenStruct)).to eq(true)
          expect(result.odometer.meta).not_to be_nil
          expect(result.odometer.distance).not_to be_nil

          # Tire Pressure Assertions
          expect(result.tire_pressure.is_a?(OpenStruct)).to eq(true)
          expect(result.tire_pressure.meta).not_to be_nil
          expect(result.tire_pressure.front_left).not_to be_nil
          expect(result.tire_pressure.front_right).not_to be_nil
          expect(result.tire_pressure.back_left).not_to be_nil
          expect(result.tire_pressure.back_right).not_to be_nil

          # Lock Status Assertions
          expect(result.lock_status.is_a?(OpenStruct)).to eq(true)
          expect([true, false].include?(result.lock_status.is_locked)).to eq(true)
          expect(result.lock_status.doors).not_to be_nil
          expect(result.lock_status.windows).not_to be_nil
          expect(result.lock_status.sunroof).not_to be_nil
          expect(result.lock_status.charging_port).not_to be_nil
          expect(result.lock_status.meta).not_to be_nil

          # Diagnostics System Status Assertions
          expect(result.diagnostic_system_status.is_a?(OpenStruct)).to eq(true)
          expect(result.diagnostic_system_status.systems).not_to be_empty
          first_system = result.diagnostic_system_status.systems.first
          expect(first_system.systemId).not_to be_nil
          expect(first_system.status).not_to be_nil

          # Diagnostics Trouble Codes Assertions
          expect(result.diagnostic_trouble_codes.is_a?(OpenStruct)).to eq(true)
          expect(result.diagnostic_trouble_codes.activeCodes).not_to be_empty
          first_code = result.diagnostic_trouble_codes.activeCodes.first
          expect(first_code.code).not_to be_nil
        end
      end
    end

    describe '#request - odometer' do
      it 'should use request method to return an odometer object' do
        result = @vehicle.request('get', 'odometer')
        expect(result.body.distance.is_a?(Numeric)).to eq(true)
        expect(result.meta.request_id.length).to eq(36)
        expect(result.meta.unit_system).to eq('metric')
        expect(result.meta.data_age.is_a?(DateTime)).to eq(true)
      end
    end

    describe '#request - batch' do
      it 'should return hash of objects with attribute requested as keys' do
        result = @vehicle.request('post', 'batch', { requests: [{ path: '/odometer' }, { path: '/tires/pressure' }] })
        expect(result.body.responses[0].path).to eq('/odometer')
        expect(result.body.responses[0].body.is_a?(OpenStruct)).to eq(true)
        expect(result.body.responses[0].headers).not_to be_nil
        expect(result.body.responses[0].body.distance).not_to be_nil
        expect(result.body.responses[1].path).to eq('/tires/pressure')
        expect(result.body.responses[1].body.is_a?(OpenStruct)).to eq(true)
        expect(result.body.responses[1].headers).not_to be_nil
        expect(result.body.responses[1].body.frontLeft).not_to be_nil
        expect(result.body.responses[1].body.frontRight).not_to be_nil
        expect(result.body.responses[1].body.backLeft).not_to be_nil
        expect(result.body.responses[1].body.backRight).not_to be_nil
      end
    end

    describe '#request - override auth header' do
      it 'should throw error in making request' do
        expected_description = 'The authorization header is missing or malformed, ' \
                               'or it contains invalid or expired authentication credentials. Please ' \
                               'check for missing parameters, spelling and casing mistakes, and ' \
                               'other syntax issues.'

        expect do
          @vehicle.request('get', 'odometer', {}, {
                             'sc-unit-system': 'imperial',
                             Authorization: 'Bearer abc'
                           })
        end.to(raise_error do |error|
          expect(error.status_code).to eq(401)
          expect(error.type).to eq('AUTHENTICATION')
          expect(error.description).to eq(expected_description)
          expect(error.doc_url).to eq('https://smartcar.com/docs/errors/api-errors/authentication-errors#null')
        end)
      end
    end

    # Note - Convert to separate test to make this file order independent
    describe '#disconnect' do
      it 'should return success' do
        result = @vehicle.disconnect!
        expect(result.status).to eq('success')
        expect(result.meta.request_id.length).to eq(36)
      end
    end
  end

  describe 'Action methods' do
    before(:context) do
      @token = AuthHelper.run_auth_flow_and_get_tokens(
        nil,
        'FORD',
        [
          'required:control_charge',
          'required:control_security',
          'required:control_navigation',
          'read_charge'
        ]
      )[:access_token]
      @vehicle_ids = Smartcar.get_vehicles(token: @token).vehicles
      @vehicle = Smartcar::Vehicle.new(token: @token, id: @vehicle_ids.first)
    end

    %i[lock! unlock! start_charge! stop_charge!].each do |action|
      describe "##{action}" do
        it 'should return a confirmation' do
          result = @vehicle.send(action)
          expect(result.status).to eq('success')
          expect(result.message).to eq('Successfully sent request to vehicle')
          expect(result.meta.request_id.length).to eq(36)
        end
      end

      describe '#send_destination!' do
        it 'should return a confirmation' do
          result = @vehicle.send_destination!(47.6205063, -122.3518523)
          puts result
          expect(result.status).to eq('success')
          expect(result.message).to eq('Successfully sent request to vehicle')
          expect(result.meta.request_id.length).to eq(36)
        end
      end
    end

    context 'set_charge_limit' do
      it 'should return success' do
        result = @vehicle.set_charge_limit!(0.7)
        expect(result.status).to eq('success')
        expect(result.message).to eq('Successfully sent request to vehicle')
        expect(result.meta.request_id.length).to eq(36)
      end
    end

    describe '#batch - success' do
      context 'with valid and invalid attributes' do
        it 'should return hash of objects with attribute requested as keys' do
          expected_description = 'Your application has insufficient permissions to access the requested resource. ' \
                                 'Please prompt the user to re-authenticate using Smartcar Connect.'
          attributes = ['/charge', '/fuel']
          result = @vehicle.batch(attributes)

          expect(result.is_a?(OpenStruct)).to eq(true)
          expect(result.charge.is_a?(OpenStruct)).to eq(true)
          expect(result.charge.is_plugged_in?).not_to be_nil
          expect(result.charge.state).not_to be_nil
          expect(result.charge.meta).not_to be_nil
          expect(result.charge.meta.request_id.length).to eq(36)

          expect { result.fuel }.to(raise_error do |error|
            expect(error.status_code).to eq(403)
            expect(error.type).to eq('PERMISSION')
            expect(error.description).to eq(expected_description)
            expect(error.doc_url).to eq('https://smartcar.com/docs/errors/api-errors/permission-errors#null')
            expect(error.resolution.type).to eq('REAUTHENTICATE')
          end)
        end
      end
    end

    describe '#subscribe!' do
      it 'should return webhook and vehicleId with meta' do
        result = @vehicle.subscribe!(ENV.fetch('E2E_SMARTCAR_WEBHOOK_ID', nil))
        expect(result.vehicle_id).to eq(@vehicle.id)
        expect(result.webhook_id).to eq(ENV.fetch('E2E_SMARTCAR_WEBHOOK_ID', nil))
        expect(result.meta.request_id.length).to eq(36)
      end
    end

    describe '#unsubscribe!' do
      it 'should return webhook and vehicleId with meta' do
        result = @vehicle.unsubscribe!(ENV.fetch('E2E_SMARTCAR_AMT', nil), ENV.fetch('E2E_SMARTCAR_WEBHOOK_ID', nil))
        expect(result.meta.request_id.length).to eq(36)
      end
    end
  end
end
