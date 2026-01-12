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

  describe 'constructor' do
    context 'with default parameters' do
      it 'uses metric unit system' do
        stub_request(:get, 'https://api.smartcar.com/v2.0/vehicles/vehicle_id/odometer')
          .with(headers: { 'Authorization' => 'Bearer token', 'sc-unit-system' => 'metric' })
          .to_return(
            {
              status: 200,
              body: { pizza: 'pasta' }.to_json
            }
          )
        result = subject.odometer
        expect(result.pizza).to eq('pasta')
      end
    end

    context 'with non default unit and version' do
      it 'uses whatever is passed' do
        subject = Smartcar::Vehicle.new(
          token: 'token',
          id: 'vehicle_id',
          options: { unit_system: 'imperial', version: 6.6 }
        )
        stub_request(:get, 'https://api.smartcar.com/v6.6/vehicles/vehicle_id/odometer')
          .with(headers: { 'Authorization' => 'Bearer token', 'sc-unit-system' => 'imperial' })
          .to_return(
            {
              status: 200,
              body: { pizza: 'pasta' }.to_json
            }
          )
        result = subject.odometer
        expect(result.pizza).to eq('pasta')
      end
    end

    context 'get request' do
      it 'uses optional flags' do
        subject = Smartcar::Vehicle.new(
          token: 'token',
          id: 'vehicle_id',
          options: { flags: { country: 'DE', flag: 'suboption' } }
        )
        stub_request(:get, 'https://api.smartcar.com/v2.0/vehicles/vehicle_id/odometer?flags=country%3ADE%20flag%3Asuboption')
          .with(headers: { 'Authorization' => 'Bearer token', 'sc-unit-system' => 'metric' })
          .to_return(
            {
              status: 200,
              body: { pizza: 'pasta' }.to_json
            }
          )
        result = subject.odometer
        expect(result.pizza).to eq('pasta')
      end
    end

    context 'post request' do
      it 'uses optional flags' do
        subject = Smartcar::Vehicle.new(
          token: 'token',
          id: 'vehicle_id',
          options: { flags: { country: 'DE', flag: 'suboption' } }
        )
        stub_request(:post, 'https://api.smartcar.com/v2.0/vehicles/vehicle_id/charge?flags=country%3ADE%20flag%3Asuboption')
          .with(headers: { 'Authorization' => 'Bearer token' }, body: { 'action' => 'START' })
          .to_return(
            {
              status: 200,
              body: { pizza: 'pasta' }.to_json
            }
          )
        result = subject.start_charge!
        expect(result.pizza).to eq('pasta')
      end
    end

    context 'delete request' do
      it 'uses optional flags' do
        subject = Smartcar::Vehicle.new(
          token: 'token',
          id: 'vehicle_id',
          options: { flags: { country: 'DE', flag: 'suboption' } }
        )
        stub_request(:delete, 'https://api.smartcar.com/v2.0/vehicles/vehicle_id/application?flags=country%3ADE%20flag%3Asuboption')
          .with(headers: { 'Authorization' => 'Bearer token' })
          .to_return(
            {
              status: 200,
              body: { pizza: 'pasta' }.to_json
            }
          )
        result = subject.disconnect!
        expect(result.pizza).to eq('pasta')
      end
    end

    context 'subscribe request' do
      it 'uses optional flags' do
        subject = Smartcar::Vehicle.new(
          token: 'token',
          id: 'vehicle_id',
          options: { flags: { country: 'DE', flag: 'suboption' } }
        )
        stub_request(:post, 'https://api.smartcar.com/v2.0/vehicles/vehicle_id/webhooks/webhook_id?flags=country:DE%20flag:suboption')
          .with(
            headers: {
              'Authorization' => 'Bearer token'
            }
          )
          .to_return(status: 200)
        subject.subscribe!('webhook_id')
      end
    end

    context 'unsubscribe request' do
      it 'uses optional flags' do
        subject = Smartcar::Vehicle.new(
          token: 'token',
          id: 'vehicle_id',
          options: { flags: { country: 'DE', flag: 'suboption' } }
        )
        stub_request(:delete, 'https://api.smartcar.com/v2.0/vehicles/vehicle_id/webhooks/webhook_id?flags=country:DE%20flag:suboption')
          .with(
            headers: {
              'Authorization' => 'Bearer amt'
            }
          )
          .to_return(status: 200)
        subject.unsubscribe!('amt', 'webhook_id')
      end
    end

    context 'with a custom service' do
      let(:mock_service) { Faraday.new(url: 'https://custom-api.smartcar.com') }

      it 'uses the provided service object' do
        subject = Smartcar::Vehicle.new(
          token: 'token',
          id: 'vehicle_id',
          options: {
            service: mock_service
          }
        )

        stub_request(:get, 'https://custom-api.smartcar.com/v2.0/vehicles/vehicle_id/odometer')
          .with(headers: { 'Authorization' => 'Bearer token', 'sc-unit-system' => 'metric' })
          .to_return(
            {
              status: 200,
              body: { pizza: 'pasta' }.to_json
            }
          )

        result = subject.odometer
        expect(result.pizza).to eq('pasta')
      end
    end
  end

  describe '#batch' do
    context 'success with some items being errors' do
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
        expect(result.is_a?(OpenStruct)).to eq(true)
        expect(result.odometer.is_a?(OpenStruct)).to eq(true)
        expect { result.location }.to(raise_error do |error|
          expect(error.status_code).to eq(409)
          expect(error.type).to eq('VEHICLE_STATE')
          expect(error.code).to eq('UNREACHABLE')
          expect(error.description).to eq(expected_description)
          expect(error.doc_url).to eq('https://smartcar.com/docs/errors/v2.0/vehicle-state/#unreachable')
          expect(error.resolution).to be_nil
          expect(error.request_id).to eq('request_id')
        end)
      end
    end

    context 'error with the batch request' do
      it 'should throw the error wihle calling batch' do
        attributes = ['/odometer', '/location']
        stub_request(:post, 'https://api.smartcar.com/v2.0/vehicles/vehicle_id/batch')
          .with(body: { requests: [{ path: '/odometer' }, { path: '/location' }] })
          .to_return(
            {
              status: 500,
              body: {
                error: 'monkeys_on_mars',
                message: 'yes, really'
              }.to_json,
              headers: {
                'sc-request-id' => 'request_id',
                'content-type' => 'application/json'
              }
            }
          )
        expect { subject.batch(attributes) }.to(raise_error do |error|
          expect(error.message).to eq('monkeys_on_mars: - yes, really')
          expect(error.type).to eq('monkeys_on_mars')
          expect(error.request_id).to eq('request_id')
        end)
      end
    end
  end

  describe '#get_signal' do
    context 'when signal_code is nil or empty' do
      it 'raises an error' do
        expect do
          subject.get_signal(nil)
        end.to raise_error(Smartcar::Base::InvalidParameterValue, 'signal_code is a required field')
        expect do
          subject.get_signal('')
        end.to raise_error(Smartcar::Base::InvalidParameterValue, 'signal_code is a required field')
      end
    end

    context 'when requesting a specific signal' do
      it 'uses the vehicle API origin and v3 version' do
        stub_request(:get, 'https://vehicle.api.smartcar.com/v3/vehicles/vehicle_id/signals/odometer-traveleddistance')
          .with(headers: { 'Authorization' => 'Bearer token' })
          .to_return(
            {
              status: 200,
              headers: {
                'content-type' => 'application/json',
                'sc-request-id' => 'signal-request-id'
              },
              body: {
                id: 'odometer-traveleddistance',
                type: 'signal',
                attributes: {
                  code: 'odometer-traveleddistance',
                  name: 'TraveledDistance',
                  group: 'Odometer',
                  status: {
                    value: 'SUCCESS'
                  },
                  body: {
                    unit: 'kilometers',
                    value: 12_345.6
                  }
                },
                meta: {
                  retrievedAt: 1_752_104_218_549,
                  oemUpdatedAt: 1_752_104_118_549
                },
                links: {
                  self: '/vehicles/vehicle_id/signals/odometer-traveleddistance'
                }
              }.to_json
            }
          )

        result = subject.get_signal('odometer-traveleddistance')

        expect(result.body.attributes.body.value).to eq(12_345.6)
        expect(result.body.attributes.body.unit).to eq('kilometers')
        expect(result.headers.content_type).to eq('application/json')
        expect(result.headers.sc_request_id).to eq('signal-request-id')
      end
    end

    context 'when signal includes query parameters with flags' do
      it 'includes flags in the request' do
        subject = Smartcar::Vehicle.new(
          token: 'token',
          id: 'vehicle_id',
          options: { flags: { country: 'DE' } }
        )

        stub_request(:get, 'https://vehicle.api.smartcar.com/v3/vehicles/vehicle_id/signals/odometer?flags=country%3ADE')
          .with(headers: { 'Authorization' => 'Bearer token' })
          .to_return(
            {
              status: 200,
              headers: { 'content-type' => 'application/json' },
              body: {
                id: 'odometer-traveleddistance',
                type: 'signal',
                attributes: {
                  code: 'odometer-traveleddistance',
                  name: 'TraveledDistance',
                  group: 'Odometer',
                  status: { value: 'SUCCESS' },
                  body: {
                    unit: 'kilometers',
                    value: 12_345.6
                  }
                }
              }.to_json
            }
          )

        result = subject.get_signal('odometer')
        expect(result.body.attributes.body.value).to eq(12_345.6)
      end
    end
  end

  describe '#get_signals' do
    context 'when requesting all signals' do
      it 'uses the vehicle API origin and v3 version' do
        stub_request(:get, 'https://vehicle.api.smartcar.com/v3/vehicles/vehicle_id/signals')
          .with(headers: { 'Authorization' => 'Bearer token' })
          .to_return(
            {
              status: 200,
              headers: {
                'content-type' => 'application/json',
                'sc-request-id' => 'signals-request-id',
                'sc-data-age' => '2023-03-15T12:00:00Z'
              },
              body: {
                signals: [
                  {
                    id: 'odometer-traveleddistance',
                    type: 'signal',
                    attributes: {
                      code: 'odometer-traveleddistance',
                      name: 'TraveledDistance',
                      group: 'Odometer',
                      status: { value: 'SUCCESS' },
                      body: {
                        unit: 'kilometers',
                        value: 12_345.6
                      }
                    }
                  },
                  {
                    id: 'odometer-traveleddistance',
                    type: 'signal',
                    attributes: {
                      code: 'odometer-traveleddistance',
                      name: 'TraveledDistance',
                      group: 'Odometer',
                      status: { value: 'SUCCESS' },
                      body: {
                        unit: 'kilometers',
                        value: 12_345.6
                      }
                    }
                  }
                ]
              }.to_json
            }
          )

        result = subject.get_signals

        expect(result.body.signals).to be_an(Array)
        expect(result.body.signals.length).to eq(2)
        expect(result.body.signals[0].id).to eq('odometer-traveleddistance')
        expect(result.body.signals[1].id).to eq('odometer-traveleddistance')
        expect(result.body.signals[0].attributes.body.value).to eq(12_345.6)
        expect(result.headers.content_type).to eq('application/json')
        expect(result.headers.sc_request_id).to eq('signals-request-id')
        expect(result.headers.sc_data_age).to eq('2023-03-15T12:00:00Z')
      end
    end

    context 'when using custom vehicle API origin via environment' do
      it 'uses the custom origin' do
        original_origin = ENV.fetch('SMARTCAR_VEHICLE_API_ORIGIN', nil)
        ENV['SMARTCAR_VEHICLE_API_ORIGIN'] = 'https://custom-vehicle-api.smartcar.com'

        stub_request(:get, 'https://custom-vehicle-api.smartcar.com/v3/vehicles/vehicle_id/signals')
          .with(headers: { 'Authorization' => 'Bearer token' })
          .to_return(
            {
              status: 200,
              headers: { 'content-type' => 'application/json' },
              body: { signals: [] }.to_json
            }
          )

        result = subject.get_signals
        expect(result.body.signals).to eq([])

        ENV['SMARTCAR_VEHICLE_API_ORIGIN'] = original_origin
      end
    end
  end
end
