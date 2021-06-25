# frozen_string_literal: true

# Custom SmartcarError class to represent errors from Smartcar APIs.
class SmartcarError < StandardError
  attr_reader :error, :code, :status_code, :request_id, :type, :description, :doc_url, :resolution, :detail

  def initialize(status, body, headers)
    if body.is_a?(String)
      super(body)
      return
    elsif body[:type] && body[:code] && body[:description]
      super("#{body[:type]}:#{body[:code]} - #{body[:description]}")
    else
      super(body[:message] || 'Unknown error')
    end

    set_attributes(status, body, headers)
  end

  private

  def set_attributes(status, body, headers)
    body.each do |attribute, value|
      instance_variable_set("@#{attribute}", value)
    end
    @request_id = body[:requestId] || headers['sc-request-id']
    @status_code = status
    @doc_url = body[:docURL]
    @resolution = @resolution.is_a?(String) ? OpenStruct.new({ type: @resolution }) : OpenStruct.new(@resolution)
  end
end
