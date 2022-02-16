# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'
RSpec.describe Smartcar::Vehicle do
  subject do
    Smartcar::Vehicle.new(
      token: 'token',
      id: 'vehicle_id'
    )
  end

  before do
    WebMock.disable_net_connect!
  end

  after do
    WebMock.allow_net_connect!
  end

  describe '#request' do
    context 'successful request with uppercase method' do
      it 'should make the request when the method name is uppercase' do
        subject = Smartcar::Vehicle.new(
          token: 'token',
          id: 'vehicle_id',
          options: { unit_system: 'imperial', version: 2.0 }
        )
        stub_request(:get, 'https://api.smartcar.com/v2.0/vehicles/vehicle_id/odometer')
          .with(headers: { 'Authorization' => 'Bearer token', 'sc-unit-system' => 'imperial' })
          .to_return(
            {
              status: 200,
              body: { pizza: 'pasta' }.to_json
            }
          )
        result = subject.request('GET', 'odometer')
        expect(result.body.pizza).to eq('pasta')
      end
    end
  end
end
