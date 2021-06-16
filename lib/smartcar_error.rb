# frozen_string_literal: true

# Custom SmartcarError class to represent errors from Smartcar APIs.
class SmartcarError < StandardError
  attr_reader :error, :code, :status_code, :request_id, :type, :description, :doc_url, :resolution, :detail

  def initialize(status, body, headers)
    @status_code = status
    if body.is_a?(String)
      super(body)
      @request_id = headers['sc-request-id']
      return
    elsif body[:type] && body[:description]
      super("#{body[:type]}:#{body[:code]} - #{body[:description]}")
    else
      super(body[:message] || 'Unknown error')
    end
    @request_id = body[:requestId] || headers['sc-request-id']
    set_attributes(body)
  end

  private

  def set_attributes(body)
    body.each do |attribute, value|
      instance_variable_set("@#{attribute}", value)
    end
    @doc_url = body[:docURL]
    return unless @resolution

    @resolution = @resolution.is_a?(String) ? OpenStruct.new({ type: @resolution }) : OpenStruct.new(@resolution)
  end
end
