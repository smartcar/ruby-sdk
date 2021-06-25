# frozen_string_literal: true

require 'byebug'
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
        headers = { 'content-type' => 'application/json' }
        error = subject.build_error(status, body_string, headers)
        expect(error.instance_of?(SmartcarError)).to be_truthy
        expect(error.status_code).to eq(504)
        expect(error.message.include?("unexpected token at 'pizza'")).to be_truthy
        expect(error.type).to eq('SDK_ERROR')
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
        expect(error.message).to eq('yes, really')
        expect(error.error).to eq('monkeys_on_mars')
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
end
