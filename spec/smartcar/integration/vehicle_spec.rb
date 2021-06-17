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
  describe '#batch - success' do
    context 'with some being errors' do
      it 'should raise for errors and return object for successfull ones' do
        attributes = ['/odometer', '/location']
        stub_request(:post, 'https://api.smartcar.com/v2.0/vehicles/vehicle_id/batch')
          .with(body: { requests: [{ path: '/odometer' }, { path: '/location' }] })
          .to_return(
            {
              status: 200,
              headers: { 'content-type' => 'application/json; charset=utf-8' },
              body:
              {
                responses: [
                  {
                    path: '/odometer',
                    body: {
                      distance: 378
                    },
                    code: 200,
                    headers: {
                      'sc-data-age': '2019-10-24T00:43:46.000Z',
                      'sc-unit-system': 'metric'
                    }
                  },
                  {
                    body: {
                      code: 'UNREACHABLE',
                      description:
                        'The vehicle was unable to perform your request because it is currently unreachable.',
                      docURL:
                        'https://smartcar.com/docs/errors/v2.0/vehicle-state/#unreachable',
                      requestId: 'request_id',
                      statusCode: 409,
                      type: 'VEHICLE_STATE',
                      resolution: nil
                    },
                    code: 409,
                    headers: {},
                    path: '/location'
                  }
                ]
              }.to_json
            }
          )
        expected_description = 'The vehicle was unable to perform your request because it is currently unreachable.'
        result = subject.batch(attributes)
        expect(result.instance_of?(OpenStruct)).to eq(true)
        expect(result.odometer.instance_of?(OpenStruct)).to eq(true)
        expect { result.location }.to(raise_error do |error|
          expect(error.status_code).to eq(409)
          expect(error.type).to eq('VEHICLE_STATE')
          expect(error.code).to eq('UNREACHABLE')
          expect(error.description).to eq(expected_description)
          expect(error.doc_url).to eq('https://smartcar.com/docs/errors/v2.0/vehicle-state/#unreachable')
          expect(error.resolution).to be_nil
        end)
      end
    end
  end
end
