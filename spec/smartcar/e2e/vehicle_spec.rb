# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar::Vehicle do
  subject { Smartcar::Vehicle }
  before(:context) do
    token_hash = AuthHelper.run_auth_flow_and_get_tokens
    @token = token_hash[:access_token]
    @vehicle_ids = Smartcar.get_vehicles(token: @token).vehicles
    @vehicle = Smartcar::Vehicle.new(token: @token, id: @vehicle_ids.first)
  end

  describe '#battery' do
    it 'should return an battery object' do
      result = @vehicle.battery
      expect(result.instance_of?(OpenStruct)).to eq(true)
      expect(result.percentage_remaining).not_to be_nil
      expect(result.range).not_to be_nil
      expect(result.meta).not_to be_nil
    end
  end

  describe '#battery_capacity' do
    it 'should return an battery_capacity object' do
      result = @vehicle.battery_capacity
      expect(result.instance_of?(OpenStruct)).to eq(true)
      expect(result.capacity).not_to be_nil
      expect(result.meta).not_to be_nil
    end
  end

  describe '#charge' do
    it 'should return an charge object' do
      result = @vehicle.charge
      expect(result.instance_of?(OpenStruct)).to eq(true)
      expect(result.is_plugged_in?).not_to be_nil
      expect(result.state).not_to be_nil
      expect(result.meta).not_to be_nil
    end
  end

  describe '#engine_oil' do
    it 'should return an engine_oil object' do
      result = @vehicle.engine_oil
      expect(result.instance_of?(OpenStruct)).to eq(true)
      expect(result.meta).not_to be_nil
      expect(result.life_remaining).not_to be_nil
    end
  end

  describe '#fuel' do
    it 'should return an fuel object' do
      result = @vehicle.fuel
      expect(result.instance_of?(OpenStruct)).to eq(true)
      expect(result.percent_remaining).not_to be_nil
      expect(result.amount_remaining).not_to be_nil
      expect(result.meta).not_to be_nil
      expect(result.range).not_to be_nil
    end
  end

  describe '#location' do
    it 'should return an location object' do
      result = @vehicle.location
      expect(result.instance_of?(OpenStruct)).to eq(true)
      expect(result.latitude).not_to be_nil
      expect(result.meta).not_to be_nil
      expect(result.longitude).not_to be_nil
    end
  end

  describe '#permissions' do
    it 'should return an permissions object' do
      result = @vehicle.permissions
      expect(result.instance_of?(OpenStruct)).to eq(true)
      expect(result.meta).not_to be_nil
      expect(result.permissions).not_to be_nil
    end
  end

  describe '#tire_pressure' do
    it 'should return an tire_pressure object' do
      result = @vehicle.tire_pressure
      expect(result.instance_of?(OpenStruct)).to eq(true)
      expect(result.meta).not_to be_nil
      expect(result.back_left).not_to be_nil
      expect(result.front_left).not_to be_nil
      expect(result.back_right).not_to be_nil
      expect(result.front_right).not_to be_nil
    end
  end

  describe '#vin' do
    it 'should return an vin string' do
      result = @vehicle.vin
      expect(result.instance_of?(String)).to eq(true)
      expect(result).not_to be_nil
    end
  end

  describe '#odometer' do
    it 'should return an odometer object' do
      result = @vehicle.odometer
      expect(result.instance_of?(OpenStruct)).to eq(true)
      expect(result.meta).not_to be_nil
      expect(result.distance).not_to be_nil
    end
  end

  describe '#batch - success' do
    context 'with valid attributes' do
      it 'should return hash of objects with attribute requested as keys' do
        attributes = ['/charge', '/battery', '/odometer']
        result = @vehicle.batch(attributes)
        expect(result.instance_of?(OpenStruct)).to eq(true)
        expect(result.charge.instance_of?(OpenStruct)).to eq(true)
        expect(result.charge.is_plugged_in?).not_to be_nil
        expect(result.charge.state).not_to be_nil
        expect(result.charge.meta).not_to be_nil
        expect(result.battery.instance_of?(OpenStruct)).to eq(true)
        expect(result.battery.percentage_remaining).not_to be_nil
        expect(result.battery.range).not_to be_nil
        expect(result.battery.meta).not_to be_nil
        expect(result.odometer.instance_of?(OpenStruct)).to eq(true)
        expect(result.odometer.meta).not_to be_nil
        expect(result.odometer.distance).not_to be_nil
      end
    end

    context 'with some invalid attributes' do
      it 'should raise InvalidParameterValue error' do
        attributes = %w[/odometer /what /where]
        expect { @vehicle.batch(attributes) }.to(raise_error do |error|
          expect(error.is_a?(ArgumentError)).to be true
          expect(error.message).to eq('Unsupported attribute(s) requested in batch  - what,where')
        end)
      end
    end
  end

  # Note - Conver to separate test to make this file order independent
  describe '#disconnect' do
    it 'should return an boolean' do
      result = @vehicle.disconnect!
      expect(result.status).to eq('success')
    end
  end
end
