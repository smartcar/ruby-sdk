# frozen_string_literal: true

class Temp
  include Smartcar::Utils
end

RSpec.describe Smartcar::Utils do
  subject do
    Temp.new
  end

  describe '#build_error' do
    context 'If content-type header does not indicate json' do
      it 'should throw Smartcar Error with body as message' do
        status = 504
        body_string = 'pizza'
        headers = {}
        error = subject.build_error(status, body_string, headers)
        expect(error.instance_of?(SmartcarError)).to be_truthy
        expect(error.status_code).to eq(504)
        expect(error.message).to eq('pizza')
      end
    end

    context 'If body is not json parsable' do
      it 'should throw Smartcar Error with SDK_ERROR' do
        status = 504
        body_string = 'pizza'
        headers = { 'content-type' => 'application/json', 'sc-request-id' => 'request_id' }
        error = subject.build_error(status, body_string, headers)
        expect(error.instance_of?(SmartcarError)).to be_truthy
        expect(error.status_code).to eq(504)
        expect(error.message.include?("unexpected token at 'pizza'")).to be_truthy
        expect(error.type).to eq('SDK_ERROR')
        expect(error.request_id).to eq('request_id')
      end
    end

    context 'If Smartcar V1 Error' do
      it 'should build the SmartcarError object' do
        status = 500
        body_string = {
          error: 'monkeys_on_mars',
          message: 'yes, really'
        }.to_json
        headers = { 'content-type' => 'application/json', 'sc-request-id' => 'request_id' }
        error = subject.build_error(status, body_string, headers)
        expect(error.instance_of?(SmartcarError)).to be_truthy
        expect(error.status_code).to eq(500)
        expect(error.message).to eq('monkeys_on_mars: - yes, really')
        expect(error.type).to eq('monkeys_on_mars')
        expect(error.request_id).to eq('request_id')
      end
    end

    context 'If Smartcar V2 Error with no resolution' do
      it 'should build the SmartcarError object' do
        status = 500
        body_string = {
          type: 'type',
          code: 'code',
          description: 'description',
          requestId: '123',
          statusCode: 500
        }.to_json
        headers = { 'content-type' => 'application/json' }
        error = subject.build_error(status, body_string, headers)
        expect(error.instance_of?(SmartcarError)).to be_truthy
        expect(error.status_code).to eq(500)
        expect(error.type).to eq('type')
        expect(error.code).to eq('code')
        expect(error.description).to eq('description')
        expect(error.resolution).to be_nil
        expect(error.request_id).to eq('123')
      end
    end

    context 'If Smartcar V2 Error with string resolution' do
      it 'should  convert resolution to object' do
        status = 500
        body_string = {
          type: 'type',
          code: 'code',
          description: 'description',
          requestId: '123',
          statusCode: 500,
          resolution: 'resolution'
        }.to_json
        headers = { 'content-type' => 'application/json' }
        error = subject.build_error(status, body_string, headers)
        expect(error.instance_of?(SmartcarError)).to be_truthy
        expect(error.status_code).to eq(500)
        expect(error.type).to eq('type')
        expect(error.code).to eq('code')
        expect(error.description).to eq('description')
        expect(error.resolution.type).to eq('resolution')
        expect(error.request_id).to eq('123')
      end
    end

    context 'If Smartcar V2 Error with object resolution' do
      it 'should keep resolution as object and construct openStruct' do
        status = 500
        body_string = {
          type: 'type',
          code: 'code',
          description: 'description',
          requestId: '123',
          statusCode: 500,
          resolution: { pizza: 'resolution' }
        }.to_json
        headers = { 'content-type' => 'application/json' }
        error = subject.build_error(status, body_string, headers)
        expect(error.instance_of?(SmartcarError)).to be_truthy
        expect(error.status_code).to eq(500)
        expect(error.type).to eq('type')
        expect(error.code).to eq('code')
        expect(error.description).to eq('description')
        expect(error.resolution.pizza).to eq('resolution')
        expect(error.request_id).to eq('123')
      end
    end

    context 'If bit-flips because of moon position' do
      it 'should still convert SmartcarError' do
        status = 500
        body_string = {
          description: 'description',
          requestId: '123',
          statusCode: 500,
          resolution: { pizza: 'resolution' }
        }.to_json
        headers = { 'content-type' => 'application/json' }
        error = subject.build_error(status, body_string, headers)
        expect(error.instance_of?(SmartcarError)).to be_truthy
        expect(error.status_code).to eq(500)
        expect(error.type).to eq('SDK_ERROR')
        expect(error.description).to eq('description')
        expect(error.resolution.pizza).to eq('resolution')
        expect(error.request_id).to eq('123')
      end
    end
  end

  describe '#build_meta' do
    context 'with valid headers' do
      it 'should build meta object with correct values' do
        headers = {
          'sc-request-id' => 'request_id',
          'sc-data-age' => '2023-05-04T07:20:50.844Z',
          'sc-unit-system' => 'metric',
          'sc-fetched-at' => '2023-05-04T07:20:51.844Z'
        }
        meta = subject.build_meta(headers)

        expect(meta.request_id).to eq('request_id')
        expect(meta.data_age).to be_a(DateTime)
        expect(meta.data_age.to_s).to include('2023-05-04T07:20:50')
        expect(meta.unit_system).to eq('metric')
        expect(meta.fetched_at).to be_a(DateTime)
        expect(meta.fetched_at.to_s).to include('2023-05-04T07:20:51')
      end
    end

    context 'with missing headers' do
      it 'should et date fields to nil when missing headers in meta object' do
        headers = {
          'sc-request-id' => 'request_id',
          'sc-unit-system' => 'metric'
        }
        meta = subject.build_meta(headers)

        expect(meta.request_id).to eq('request_id')
        expect(meta.unit_system).to eq('metric')
        expect(meta.data_age).to be_nil
        expect(meta.fetched_at).to be_nil
      end
    end

    context 'with invalid date formats' do
      it 'should set date fields to nil when they cannot be parsed' do
        headers = {
          'sc-request-id' => 'request_id',
          'sc-data-age' => 'invalid-date-format',
          'sc-unit-system' => 'metric',
          'sc-fetched-at' => 'another-invalid-date'
        }
        meta = subject.build_meta(headers)

        expect(meta.request_id).to eq('request_id')
        expect(meta.data_age).to be_nil
        expect(meta.unit_system).to eq('metric')
        expect(meta.fetched_at).to be_nil
      end
    end
  end
end
