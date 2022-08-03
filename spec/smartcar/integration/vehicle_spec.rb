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
end
