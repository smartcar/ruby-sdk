# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar do
  subject { Smartcar }

  before do
    @api_origin = ENV['SMARTCAR_API_ORIGIN']
    ENV['SMARTCAR_API_ORIGIN'] = 'https://pizza.pasta.pi'
    WebMock.disable_net_connect!
  end

  after do
    WebMock.allow_net_connect!
    ENV['SMARTCAR_API_ORIGIN'] = @api_origin
  end

  describe '.get_compatibility' do
    context 'when client id is not set' do
      it 'should raise error' do
        client_id = ENV['E2E_SMARTCAR_CLIENT_ID']
        ENV.delete('E2E_SMARTCAR_CLIENT_ID')

        expect { subject.get_compatibility(vin: 'vin', scope: ['scope']) }.to(raise_error do |error|
          expect(error.message).to eq('Environment variable E2E_SMARTCAR_CLIENT_ID not found !')
        end)
        ENV['E2E_SMARTCAR_CLIENT_ID'] = client_id
      end
    end

    context 'when client secret is not set' do
      it 'should raise error if client secret is not set' do
        client_secret = ENV['E2E_SMARTCAR_CLIENT_SECRET']
        ENV.delete('E2E_SMARTCAR_CLIENT_SECRET')

        expect { subject.get_compatibility(vin: 'vin', scope: ['scope']) }.to(raise_error do |error|
          expect(error.message).to eq('Environment variable E2E_SMARTCAR_CLIENT_SECRET not found !')
        end)
        ENV['E2E_SMARTCAR_CLIENT_SECRET'] = client_secret
      end
    end

    context 'when test mode is passed' do
      it 'should add it in query params' do
        scopes = %w[read_odometer read_location]
        stub_request(:get, 'https://pizza.pasta.pi/v2.0/compatibility')
          .with(
            basic_auth: [ENV['E2E_SMARTCAR_CLIENT_ID'], ENV['E2E_SMARTCAR_CLIENT_SECRET']],
            query: { country: 'US', mode: 'test', scope: 'read_odometer read_location', vin: 'vin' }
          )
          .to_return(
            {
              status: 200,
              headers: { 'content-type' => 'application/json; charset=utf-8' },
              body:
              {
                compatible: true
              }.to_json
            }
          )

        subject.get_compatibility(
          vin: 'vin',
          scope: scopes,
          country: 'US',
          options: {
            test_mode: true
          }
        )
      end
    end

    context 'when test mode compatibility level passed' do
      it 'should add it in query params and default mode to test' do
        scopes = %w[read_odometer read_location]
        stub_request(:get, 'https://pizza.pasta.pi/v2.0/compatibility')
          .with(
            basic_auth: [ENV['E2E_SMARTCAR_CLIENT_ID'], ENV['E2E_SMARTCAR_CLIENT_SECRET']],
            query: { country: 'US', mode: 'test', scope: 'read_odometer read_location', vin: 'vin',
                     test_mode_compatibility_level: 'pizza' }
          )
          .to_return(
            {
              status: 200,
              headers: { 'content-type' => 'application/json; charset=utf-8' },
              body:
              {
                compatible: true
              }.to_json
            }
          )

        subject.get_compatibility(
          vin: 'vin',
          scope: scopes,
          country: 'US',
          options: {
            test_mode_compatibility_level: 'pizza'
          }
        )
      end
    end

    context 'when flags object id passed' do
      it 'should build and add the flags to URL params' do
        scopes = %w[read_odometer read_location]
        stub_request(:get, 'https://pizza.pasta.pi/v2.0/compatibility?country=US&flags=flagA:a%20flagB:b&scope=read_odometer%20read_location&vin=vin')
          .with(
            basic_auth: [ENV['E2E_SMARTCAR_CLIENT_ID'], ENV['E2E_SMARTCAR_CLIENT_SECRET']]
          )
          .to_return(
            {
              status: 200,
              headers: { 'content-type' => 'application/json; charset=utf-8' },
              body:
              {
                compatible: true
              }.to_json
            }
          )

        subject.get_compatibility(
          vin: 'vin',
          scope: scopes,
          country: 'US',
          options: {
            flags: { flagA: 'a', flagB: 'b' }
          }
        )
      end
    end

    context 'when a service object is provided' do
      let(:mock_service) { Faraday.new(url: 'https://custom-api.smartcar.com') }

      it 'should use the provided service object' do
        scopes = %w[read_odometer read_location]
        stub_request(:get, 'https://custom-api.smartcar.com/v2.0/compatibility?country=US&scope=read_odometer%20read_location&vin=vin')
          .with(
            basic_auth: [ENV['E2E_SMARTCAR_CLIENT_ID'], ENV['E2E_SMARTCAR_CLIENT_SECRET']]
          )
          .to_return(
            {
              status: 200,
              headers: { 'content-type' => 'application/json; charset=utf-8' },
              body:
              {
                compatible: true
              }.to_json
            }
          )

        subject.get_compatibility(
          vin: 'vin',
          scope: scopes,
          country: 'US',
          options: {
            service: mock_service
          }
        )
      end
    end
  end

  describe '.get_user' do
    context 'when a service object is provided' do
      let(:mock_service) { Faraday.new(url: 'https://custom-api.smartcar.com') }

      it 'should use the provided service object' do
        stub_request(:get, 'https://custom-api.smartcar.com/v2.0/user')
          .with(headers: { 'Authorization' => 'Bearer token' })
          .to_return(
            {
              status: 200,
              headers: { 'content-type' => 'application/json; charset=utf-8' },
              body:
              {
                user: { id: 'abc12345-6789-1234-abcd-123abc123abc' }
              }.to_json
            }
          )

        subject.get_user(
          token: 'token',
          options: {
            service: mock_service
          }
        )
      end
    end
  end

  describe '.get_vehicles' do
    it 'should return all vehicle ids associated with the account' do
      stub_request(:get, 'https://pizza.pasta.pi/v2.0/vehicles?limit=1')
        .with(headers: { 'Authorization' => 'Bearer token' })
        .to_return(
          {
            status: 200,
            headers: { 'content-type' => 'application/json; charset=utf-8' },
            body:
            {
              vehicles: ['vehicle1'],
              paging: { count: 1, offset: 0 }
            }.to_json
          }
        )
      response = subject.get_vehicles(token: 'token', paging: { limit: 1 })

      expect(response.vehicles.is_a?(Array)).to be_truthy
      expect(response.vehicles[0] == 'vehicle1').to be_truthy
      expect(response.paging.is_a?(OpenStruct)).to be_truthy
      expect(response.paging.offset).to be(0)
      expect(response.paging.count).to be(1)
    end

    context 'when a service object is provided' do
      let(:mock_service) { Faraday.new(url: 'https://custom-api.smartcar.com') }

      it 'should use the provided service object' do
        stub_request(:get, 'https://custom-api.smartcar.com/v2.0/vehicles?limit=1')
          .with(headers: { 'Authorization' => 'Bearer token' })
          .to_return(
            {
              status: 200,
              headers: { 'content-type' => 'application/json; charset=utf-8' },
              body:
              {
                vehicles: ['vehicle1'],
                paging: { count: 1, offset: 0 }
              }.to_json
            }
          )

        subject.get_vehicles(
          token: 'token',
          paging: { limit: 1 },
          options: {
            service: mock_service
          }
        )
      end
    end
  end
end
