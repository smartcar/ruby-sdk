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
        expect(result.distance.instance_of?(Float)).to eq(true)
        expect(result.meta.request_id.length).to eq(36)
        expect(result.meta.unit_system).to eq('metric')
        expect(result.meta.data_age.is_a?(DateTime)).to eq(true)
      end
    end

    describe '#batch - success' do
      context 'with valid attributes' do
        it 'should return hash of objects with attribute requested as keys' do
          attributes = ['/charge', '/battery', '/odometer']
          result = @vehicle.batch(attributes)
          expect(result.is_a?(OpenStruct)).to eq(true)
          expect(result.charge.is_a?(OpenStruct)).to eq(true)
          expect(result.charge.is_plugged_in?).not_to be_nil
          expect(result.charge.state).not_to be_nil
          expect(result.charge.meta).not_to be_nil
          expect(result.charge.meta.request_id.length).to eq(36)
          expect(result.battery.is_a?(OpenStruct)).to eq(true)
          expect(result.battery.percentage_remaining).not_to be_nil
          expect(result.battery.range).not_to be_nil
          expect(result.battery.meta).not_to be_nil
          expect(result.odometer.is_a?(OpenStruct)).to eq(true)
          expect(result.odometer.meta).not_to be_nil
          expect(result.odometer.distance).not_to be_nil
        end
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
        'TESLA',
        ['required:control_charge', 'required:control_security', 'read_charge']
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
    end

    describe '#batch - success' do
      context 'with valid and invalid attributes' do
        it 'should return hash of objects with attribute requested as keys' do
          expected_description = 'Your application has insufficient permissions to access the requested resource.'\
          ' Please prompt the user to re-authenticate using Smartcar Connect.'
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
            expect(error.doc_url).to eq('https://smartcar.com/docs/errors/v2.0/other-errors/#permission')
            expect(error.resolution.type).to eq('REAUTHENTICATE')
          end)
        end
      end
    end

    describe '#subscribe!' do
      it 'should return webhook and vehicleId with meta' do
        result = @vehicle.subscribe!(ENV['E2E_SMARTCAR_WEBHOOK_ID'])
        expect(result.vehicle_id).to eq(@vehicle.id)
        expect(result.webhook_id).to eq(ENV['E2E_SMARTCAR_WEBHOOK_ID'])
        expect(result.meta.request_id.length).to eq(36)
      end
    end

    describe '#unsubscribe!' do
      it 'should return webhook and vehicleId with meta' do
        result = @vehicle.unsubscribe!(ENV['E2E_SMARTCAR_AMT'], ENV['E2E_SMARTCAR_WEBHOOK_ID'])
        expect(result.meta.request_id.length).to eq(36)
      end
    end
  end
end
