# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar::Vehicle do
  subject { Smartcar::Vehicle }
  let(:vehicle) do
    url = Smartcar::Oauth.authorization_url(AuthHelper.auth_client_params)
    token_hash = Smartcar::Oauth.get_token(AuthHelper.run_auth_flow(url))
    token = token_hash[:access_token]
    ids =  Smartcar::Vehicle.all_vehicle_ids(token: token)
    Smartcar::Vehicle.new(token: token, id: ids.first)
  end

  describe '.compatible?' do
    it 'should response if vehicle is compatible for given scopes' do
      tesla_vin = '5YJXCDE22HF068739'
      audi_vin = 'WAUAFAFL1GN014882'
      scopes = %w[read_odometer read_location]

      result = subject.compatible?(vin: tesla_vin, scope: scopes)
      expect(result).to be_truthy

      result = subject.compatible?(vin: audi_vin, scope: scopes)
      expect(result).to be_falsey
    end
  end

  describe '#battery' do
    it 'should return an battery object' do
      result = vehicle.battery
      expect(result.instance_of?(Smartcar::Battery)).to eq(true)
      expect(result.percentage_remaining).not_to be_nil
      expect(result.range).not_to be_nil
      expect(result.meta).not_to be_nil
    end
  end

  describe '#charge' do
    it 'should return an charge object' do
      result = vehicle.charge
      expect(result.instance_of?(Smartcar::Charge)).to eq(true)
      expect(result.is_plugged_in?).not_to be_nil
      expect(result.state).not_to be_nil
      expect(result.meta).not_to be_nil
    end
  end

  describe '#engine_oil' do
    it 'should return an engine_oil object' do
      result = vehicle.engine_oil
      expect(result.instance_of?(Smartcar::EngineOil)).to eq(true)
      expect(result.meta).not_to be_nil
      expect(result.life_remaining).not_to be_nil
    end
  end

  describe '#fuel' do
    it 'should return an fuel object' do
      result = vehicle.fuel
      expect(result.instance_of?(Smartcar::Fuel)).to eq(true)
      expect(result.percent_remaining).not_to be_nil
      expect(result.amount_remaining).not_to be_nil
      expect(result.meta).not_to be_nil
      expect(result.range).not_to be_nil
    end
  end

  describe '#location' do
    it 'should return an location object' do
      result = vehicle.location
      expect(result.instance_of?(Smartcar::Location)).to eq(true)
      expect(result.latitude).not_to be_nil
      expect(result.meta).not_to be_nil
      expect(result.longitude).not_to be_nil
    end
  end

  describe '#permissions' do
    it 'should return an permissions object' do
      result = vehicle.permissions
      expect(result.instance_of?(Smartcar::Permissions)).to eq(true)
      expect(result.meta).not_to be_nil
      expect(result.permissions).not_to be_nil
    end
  end

  describe '#tire_pressure' do
    it 'should return an tire_pressure object' do
      result = vehicle.tire_pressure
      expect(result.instance_of?(Smartcar::TirePressure)).to eq(true)
      expect(result.meta).not_to be_nil
      expect(result.back_left).not_to be_nil
      expect(result.front_left).not_to be_nil
      expect(result.back_right).not_to be_nil
      expect(result.front_right).not_to be_nil
    end
  end

  describe '#vin' do
    it 'should return an vin string' do
      result = vehicle.vin
      expect(result.instance_of?(String)).to eq(true)
      expect(result).not_to be_nil
    end
  end

  describe '#odometer' do
    it 'should return an odometer object' do
      result = vehicle.odometer
      expect(result.instance_of?(Smartcar::Odometer)).to eq(true)
      expect(result.meta).not_to be_nil
      expect(result.distance).not_to be_nil
    end
  end

  describe '#batch - success' do
    context 'with valid attributes' do
      it 'should return hash of objects with attribute requested as keys' do
        attributes = %I[charge battery odometer]
        result = vehicle.batch(attributes)
        expect(result.instance_of?(Hash)).to eq(true)
        expect(result.keys).to match_array(attributes)
        expect(result[:charge].instance_of?(Smartcar::Charge)).to eq(true)
        expect(result[:charge].is_plugged_in?).not_to be_nil
        expect(result[:charge].state).not_to be_nil
        expect(result[:charge].meta).not_to be_nil
        expect(result[:battery].instance_of?(Smartcar::Battery)).to eq(true)
        expect(result[:battery].percentage_remaining).not_to be_nil
        expect(result[:battery].range).not_to be_nil
        expect(result[:battery].meta).not_to be_nil
        expect(result[:odometer].instance_of?(Smartcar::Odometer)).to eq(true)
        expect(result[:odometer].meta).not_to be_nil
        expect(result[:odometer].distance).not_to be_nil
      end
    end

    context 'with some invalid attributes' do
      it 'should raise InvalidParameterValue error' do
        attributes = %I[odometer what where]
        expect { vehicle.batch(attributes) }.to raise_error(Smartcar::Base::InvalidParameterValue)
      end
    end
  end
end
