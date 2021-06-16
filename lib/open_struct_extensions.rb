# frozen_string_literal: true

# Extension to OpenStruct to convert a nested OpenStruct object to a hash.
# Using this method any of the API response can be converted back to hash
# or JSON (from hash) for convenience.
# Example Usage :
# response = {a: { b: {c: "test", d: [{x: 1}, {y: 3}]}}}
class OpenStruct
  def deep_to_h
    to_h.transform_values do |value|
      case value
      when is_a?(OpenStruct)
        value.deep_to_h
      when is_a?(Array)
        value.map { |item| item.is_a?(OpenStruct) ? item.deep_to_h : item }
      else
        value
      end
    end
  end
end
