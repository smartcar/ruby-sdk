RSpec.describe Smartcar::Vehicle do
  let(:id) { 'abc-123-def-456' }
  let(:vehicle) { Smartcar::Vehicle.new(token: "fake-token", id: id) }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:mock_service) { Faraday.new {|conn| conn.adapter :test, stubs} }

  before do
    allow(vehicle).to receive(:service).and_return(mock_service)
  end

  describe 'vehicle_attributes' do
    before do
      stubs.get("/v1.0/vehicles/#{id}") do |env|
        # [HTTP status, Response headers, Response body]
        [
          200,
          {'Content-Type': 'application/json'},
          {
            'id': id,
            'make': 'TESLA',
            'model': 'Model S',
            'year': 2014
          }.to_json
        ]
      end
    end

    it 'returns a VehicleAttributes object' do
      result = vehicle.vehicle_attributes

      expect(result).to be_a(Smartcar::VehicleAttributes)
      expect(result.id).to eq(id)
      expect(result.make).to eq('TESLA')
      expect(result.model).to eq('Model S')
      expect(result.year).to eq(2014)
    end
  end

  describe 'vin' do
    let(:vin) { '1234A67Q90F2T4567' }

    before do
      stubs.get("/v1.0/vehicles/#{id}/vin") do |env|
        # [HTTP status, Response headers, Response body]
        [200, {'Content-Type': 'application/json'}, {'vin': vin}.to_json]
      end
    end

    it 'returns the vin' do
      expect(vehicle.vin).to eq(vin)
    end
  end

  describe 'disconnect!' do
    before do
      stubs.delete("/v1.0/vehicles/#{id}/application") do |env|
        # [HTTP status, Response headers, Response body]
        [200, {'Content-Type': 'application/json'}, {'status': 'success'}.to_json]
      end
    end

    it 'disconnects the vehicle' do
      expect(vehicle.disconnect!).to be(true)
    end
  end
end
