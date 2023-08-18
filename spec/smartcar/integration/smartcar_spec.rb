# frozen_string_literal: true

require_relative '../helpers/auth_helper'
require_relative '../../spec_helper'

RSpec.describe Smartcar do
  subject { Smartcar }

  before do
    @api_origin = ENV['SMARTCAR_API_ORIGIN']
    ENV['SMARTCAR_API_ORIGIN'] = 'https://pizza.pasta.pi'
    @management_origin = ENV['SMARTCAR_MANAGEMENT_API_ORIGIN']
    ENV['SMARTCAR_MANAGEMENT_API_ORIGIN'] = 'https://pizza.pasta.pi'
    @amt = 'some-token'
    WebMock.disable_net_connect!
  end

  after do
    WebMock.allow_net_connect!
    ENV['SMARTCAR_API_ORIGIN'] = @api_origin
    ENV['SMARTCAR_MANAGEMENT_API_ORIGIN'] = @management_origin
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

    context 'when mode is invalid' do
      it 'should raise error if mode is not live, test, or simulated' do
        expect do
          subject.get_compatibility(vin: 'vin', scope: ['scope'], options: { mode: 'invalid' })
        end.to(raise_error do |error|
                 expect(error.message).to eq(
                   'The "mode" parameter MUST be one of the following: \'test\', \'live\', \'simulated\''
                 )
               end)
      end
    end

    context 'when vin is nil' do
      it 'should raise error' do
        expect do
          subject.get_compatibility(vin: nil, scope: ['scope'], options: { mode: 'invalid' })
        end.to(raise_error do |error|
                 expect(error.message).to eq('vin is a required field')
               end)
      end
    end

    context 'when scope is nil or empty' do
      it 'should raise error' do
        expect do
          subject.get_compatibility(vin: 'vin', scope: [], options: { mode: 'invalid' })
        end.to(raise_error do |error|
                 expect(error.message).to eq('scope is a required field')
               end)

        expect do
          subject.get_compatibility(vin: 'vin', scope: nil, options: { mode: 'invalid' })
        end.to(raise_error do |error|
                 expect(error.message).to eq('scope is a required field')
               end)
      end
    end

    context 'when mode is set to simulated' do
      it 'should add it in query params' do
        scopes = %w[read_odometer read_location]
        stub_request(:get, 'https://pizza.pasta.pi/v2.0/compatibility')
          .with(
            basic_auth: [ENV['E2E_SMARTCAR_CLIENT_ID'], ENV['E2E_SMARTCAR_CLIENT_SECRET']],
            query: { country: 'US', mode: 'simulated', scope: 'read_odometer read_location', vin: 'vin' }
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

        response = subject.get_compatibility(
          vin: 'vin',
          scope: scopes,
          country: 'US',
          options: {
            mode: 'simulated'
          }
        )
        expect(response.compatible).to be true
      end
    end

    context 'when test_mode is set to true' do
      it 'should add mode=test in query params' do
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

        response = subject.get_compatibility(
          vin: 'vin',
          scope: scopes,
          country: 'US',
          options: {
            test_mode: true
          }
        )
        expect(response.compatible).to be true
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

        response = subject.get_compatibility(
          vin: 'vin',
          scope: scopes,
          country: 'US',
          options: {
            test_mode_compatibility_level: 'pizza'
          }
        )
        expect(response.compatible).to be true
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

        response = subject.get_compatibility(
          vin: 'vin',
          scope: scopes,
          country: 'US',
          options: {
            flags: { flagA: 'a', flagB: 'b' }
          }
        )
        expect(response.compatible).to be true
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

        response = subject.get_compatibility(
          vin: 'vin',
          scope: scopes,
          country: 'US',
          options: {
            service: mock_service
          }
        )
        expect(response.compatible).to be true
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

        response = subject.get_user(
          token: 'token',
          options: {
            service: mock_service
          }
        )
        expect(response.user.id).to eq('abc12345-6789-1234-abcd-123abc123abc')
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

        response = subject.get_vehicles(
          token: 'token',
          paging: { limit: 1 },
          options: {
            service: mock_service
          }
        )
        expect(response.vehicles.is_a?(Array)).to be_truthy
        expect(response.vehicles[0] == 'vehicle1').to be_truthy
        expect(response.paging.is_a?(OpenStruct)).to be_truthy
        expect(response.paging.offset).to be(0)
        expect(response.paging.count).to be(1)
      end
    end
  end

  describe '.get_connections' do
    it 'should return all connections associated with the amt (application management token)' do
      header_token = subject.generate_basic_management_auth(@amt)

      stub_request(:get, 'https://pizza.pasta.pi/v2.0/management/connections?limit=10')
        .with(headers: { 'Authorization' => "Basic #{header_token}" })
        .to_return(
          {
            status: 200,
            headers: { 'content-type' => 'application/json; charset=utf-8' },
            body:
            {
              connections: [
                {
                  connectedAt: '2021-12-25T14:48:00.000Z',
                  userId: 'user-id-7',
                  vehicleId: 'vehicle-id-1'
                },
                {
                  connectedAt: '2020-10-05T14:48:00.000Z',
                  userId: 'user-id-6',
                  vehicleId: 'vehicle-id-2'
                }
              ],
              paging: { cursor: nil }
            }.to_json
          }
        )
      response = subject.get_connections(amt: @amt)

      expect(response.connections.is_a?(Array)).to be_truthy
      expect(response.connections[0].vehicleId).to eq('vehicle-id-1')
      expect(response.paging.is_a?(OpenStruct)).to be_truthy
      expect(response.paging.cursor).to be nil
    end

    it 'should return all connections based on given additional filters and paging options' do
      header_token = subject.generate_basic_management_auth(@amt)

      stub_request(:get, 'https://pizza.pasta.pi/v2.0/management/connections?limit=13&user_id=user_id&cursor=cursor')
        .with(headers: { 'Authorization' => "Basic #{header_token}" })
        .to_return(
          {
            status: 200,
            headers: { 'content-type' => 'application/json; charset=utf-8' },
            body:
            {
              connections: [
                {
                  connectedAt: '2021-12-25T14:48:00.000Z',
                  userId: 'user_id',
                  vehicleId: 'vehicle-id-1'
                },
                {
                  connectedAt: '2020-10-05T14:48:00.000Z',
                  userId: 'user_id',
                  vehicleId: 'vehicle-id-2'
                }
              ],
              paging: { cursor: 'cursor2' }
            }.to_json
          }
        )
      response = subject.get_connections(amt: @amt, filter: { user_id: 'user_id' },
                                         paging: { cursor: 'cursor', limit: 13 })

      expect(response.connections.is_a?(Array)).to be_truthy
      expect(response.connections[0].vehicleId).to eq('vehicle-id-1')
      expect(response.paging.is_a?(OpenStruct)).to be_truthy
      expect(response.paging.cursor).to eq('cursor2')
    end
  end

  describe '.delete_connections' do
    context 'when both user_id and vehicle_id are provided' do
      it 'raises an error' do
        expect do
          subject.delete_connections(amt: @amt, filter: { user_id: 'user_id', vehicle_id: 'vehicle_id' })
        end.to(raise_error do |error|
                 expect(error.message).to eq(
                   'Filter can contain EITHER user_id OR vehicle_id, not both.'
                 )
               end)
      end
    end

    context 'when neither user_id or vehicle_id is provided' do
      it 'raises an error' do
        expect do
          subject.delete_connections(amt: @amt)
        end.to(raise_error do |error|
                 expect(error.message).to eq(
                   'Filter needs one of user_id OR vehicle_id.'
                 )
               end)
      end
    end

    it 'deletes connections by user_id' do
      header_token = subject.generate_basic_management_auth(@amt)

      stub_request(:delete, 'https://pizza.pasta.pi/v2.0/management/connections?user_id=user_id')
        .with(headers: { 'Authorization' => "Basic #{header_token}" })
        .to_return(
          {
            status: 200,
            headers: { 'content-type' => 'application/json; charset=utf-8' },
            body:
            {
              connections: [
                {
                  connectedAt: '2021-12-25T14:48:00.000Z',
                  userId: 'user_id',
                  vehicleId: 'vehicle-id-1'
                }
              ]
            }.to_json
          }
        )
      response = subject.delete_connections(amt: @amt, filter: { user_id: 'user_id' })

      expect(response.connections.is_a?(Array)).to be_truthy
      expect(response.connections[0].userId).to eq('user_id')
    end

    it 'deletes connections by vehicle_id' do
      header_token = subject.generate_basic_management_auth(@amt)

      stub_request(:delete, 'https://pizza.pasta.pi/v2.0/management/connections?vehicle_id=vehicle_id')
        .with(headers: { 'Authorization' => "Basic #{header_token}" })
        .to_return(
          {
            status: 200,
            headers: { 'content-type' => 'application/json; charset=utf-8' },
            body:
            {
              connections: [
                {
                  connectedAt: '2021-12-25T14:48:00.000Z',
                  userId: 'user_id',
                  vehicleId: 'vehicle_id'
                }
              ]
            }.to_json
          }
        )
      response = subject.delete_connections(amt: @amt, filter: { vehicle_id: 'vehicle_id' })

      expect(response.connections.is_a?(Array)).to be_truthy
      expect(response.connections[0].vehicleId).to eq('vehicle_id')
    end
  end
end
