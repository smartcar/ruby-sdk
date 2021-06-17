# frozen_string_literal: true

# Custom SmartcarError class to represent errors from Smartcar APIs.
class SmartcarError < StandardError
  attr_reader :error, :code, :status_code, :request_id, :type, :description, :doc_url, :resolution, :detail

  def initialize(status, body, headers)
    body.each do |attribute, value|
      instance_variable_set("@#{attribute}", value)
    end
    @request_id = body['requestId'] || headers['sc-request-id']
    @status_code = status || body['statusCode']
    @doc_url = body['docURL']
    @description = @message if @error.is_a?(String)
    super(get_message)
  end

  private

  def get_message
    if @type && @code
      "#{@type}:#{@code} - #{@description}"
    elsif @description
      @description
    else
      body
    end
  end
end
