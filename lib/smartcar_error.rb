# frozen_string_literal: true

# Custom SmartcarError class to represent errors from Smartcar APIs.
class SmartcarError < StandardError
  attr_reader :code, :status_code, :request_id, :type, :description, :doc_url, :resolution, :detail, :retry_after

  def initialize(status, body, headers)
    @status_code = status
    if body.is_a?(String)
      super(body)
      @request_id = headers['sc-request-id']
      return
    end
    if headers['retry-after']
      @retry_after = headers['retry-after']
    end
    body = coerce_attributes(body)

    super("#{body[:type]}:#{body[:code]} - #{body[:description]}")
    @request_id = body[:requestId] || headers['sc-request-id']
    set_attributes(body)
  end

  private

  def coerce_attributes(body)
    body[:type] = body.delete(:error) if body[:error]
    unless body[:description]
      body[:description] = if body[:error_description]
                             body.delete(:error_description)
                           elsif body[:message]
                             body.delete(:message)
                           else
                             'Unknown error'
                           end
    end

    body
  end

  def set_attributes(body)
    body.each do |attribute, value|
      instance_variable_set("@#{attribute}", value)
    end
    @doc_url = body[:docURL]
    @type = @error if @error

    return unless @resolution

    @resolution = @resolution.is_a?(String) ? OpenStruct.new({ type: @resolution }) : OpenStruct.new(@resolution)
  end
end
