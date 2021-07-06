# frozen_string_literal: true

module Smartcar
  # AuthClient class to take care of the Oauth 2.0 with Smartcar APIs
  #
  class AuthClient
    include Smartcar::Utils

    attr_reader :redirect_uri, :client_id, :client_secret, :scope, :mode, :flags, :origin

    # Constructor for a client object
    #
    # @param [Hash] options
    # @option options[:client_id] [String] - Client ID, if not passed fallsback to ENV['SMARTCAR_CLIENT_ID']
    # @option options[:client_secret] [String] - Client Secret, if not passed fallsback to ENV['SMARTCAR_CLIENT_SECRET']
    # @option options[:redirect_uri] [String] - Redirect URI, if not passed fallsback to ENV['SMARTCAR_REDIRECT_URI']
    # @option options[:test_mode] [Boolean] - Setting this to 'true' runs it in test mode.
    # @option options[:origin] [String] - Origin host for debugging
    #
    # @return [Smartcar::AuthClient] Returns a Smartcar::AuthClient Object that has other methods
    def initialize(options)
      options[:redirect_uri] ||= get_config('SMARTCAR_REDIRECT_URI')
      options[:client_id] ||= get_config('SMARTCAR_CLIENT_ID')
      options[:client_secret] ||= get_config('SMARTCAR_CLIENT_SECRET')
      options[:mode] = options[:test_mode].is_a?(TrueClass) ? TEST : LIVE
      options[:origin] = options[:origin] || OAUTH_HOST
      super
    end

    # Generate the OAuth authorization URL.
    # @param scope [Array<String>] Array of permissions that specify what the user can access
    #   EXAMPLE : ['read_odometer', 'read_vehicle_info', 'required:read_location']
    # For further details refer to https://smartcar.com/docs/guides/scope/
    # @param [Hash] options
    # @option options[:force_prompt] [Boolean] - Setting `force_prompt` to
    # `true` will show the permissions approval screen on every authentication
    # attempt, even if the user has previously consented to the exact scope of
    # permissions.
    # @option options[:single_select] [Hash] - An optional object that sets the
    # behavior of the grant dialog displayed to the user. Object can contain two keys :
    # - enabled - Boolean value, if set to `true`,
    #   `single_select` limits the user to selecting only one vehicle.
    # - vin - String vin, if set, Smartcar will only authorize the vehicle
    #   with the specified VIN.
    # See the [Single Select guide](https://smartcar.com/docs/guides/single-select/) for more information.
    # @option options[:state] [String] - OAuth state parameter passed to the
    # redirect uri. This parameter may be used for identifying the user who
    # initiated the request.
    # @option options[:make_bypass] [String] - `make_bypass' is an optional parameter that allows
    # users to bypass the car brand selection screen.
    # For a complete list of supported makes, please see our
    # [API Reference](https://smartcar.com/docs/api#authorization) documentation.
    # @option options[:flags] [Hash] - A hash of flag name string as key and a string or boolean value.
    #
    # @return [String] Authorization URL string
    def get_auth_url(scope, options = {})
      initialize_auth_parameters(scope, options)
      add_single_select_options(options[:single_select])
      client.auth_code.authorize_url(@auth_parameters)
    end

    # Generates the tokens hash using the code returned in oauth process.
    # @param code [String] This is the code that is returned after user
    # visits and authorizes on the authorization URL.
    # @param [Hash] options
    # @option options[:flags] [Hash] - A hash of flag name string as key and a string or boolean value.
    #
    # @return [Hash] Hash of token, refresh token, expiry info and token type
    def exchange_code(code, options = {})
      set_token_url(options[:flags])

      client.auth_code
            .get_token(code, redirect_uri: redirect_uri)
            .to_hash
    end

    # Refreshing the access token
    # @param token [String] refresh_token received during token exchange
    # @param [Hash] options
    # @option options[:flags] [Hash] - A hash of flag name string as key and a string or boolean value.
    #
    # @return [Hash] Hash of token, refresh token, expiry info and token type
    def exchange_refresh_token(token, options = {})
      set_token_url(options[:flags])

      token_object = OAuth2::AccessToken.from_hash(client, { refresh_token: token })
      token_object = token_object.refresh!
      token_object.to_hash
    end

    # Checks if token is expired using Oauth2 classes
    # @param expires_at [Number] expires_at as time since epoch
    #
    # @return [Boolean]
    def expired?(expires_at)
      OAuth2::AccessToken.from_hash(client, { expires_at: expires_at }).expired?
    end

    private

    def set_token_url(flags)
      params = {}
      params[:flags] = build_flags(flags) if flags
      # Note - The inbuild interface to get the token does not allow any way to pass additional
      # URL params. Hence building the token URL with the flags and setting it in client.
      client.options[:token_url] = client.connection.build_url('/oauth/token', params).request_uri
    end

    def initialize_auth_parameters(scope, options)
      @auth_parameters = {
        response_type: CODE,
        redirect_uri: redirect_uri,
        mode: mode,
        state: options[:state],
        make: options[:make],
        approval_prompt: options[:force_prompt] ? FORCE : AUTO,
        flags: build_flags(options[:flags]),
        scope: scope.join(' ')
      }
    end

    def build_flags(flags)
      return unless flags

      flags.map { |key, value| "#{key}:#{value}" }.join(' ')
    end

    def add_single_select_options(single_select)
      return unless single_select

      if single_select[:vin]
        @auth_parameters[:single_select_vin] = single_select[:vin]
        @auth_parameters[:single_select] = true
      elsif !single_select[:enabled].nil?
        @auth_parameters[:single_select] = single_select[:enabled]
      end
    end

    # gets the Oauth Client object
    #
    # @return [OAuth2::Client] A Oauth Client object.
    def client
      @client ||= OAuth2::Client.new(client_id,
                                     client_secret,
                                     site: origin)
    end
  end
end
