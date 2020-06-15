module Smartcar
  # Oauth class to take care of the Oauth 2.0 with Smartcar APIs
  #
  class Oauth < Base
    extend Utils
    # By default users are not shown the permission dialog if they have already
    # approved the set of scopes for this application. The application can elect
    # to always display the permissions dialog to the user by setting
    # approval_prompt to `force`.
    #
    # @param options [Hash]
    # @option options[:client_id] [String] - Client ID, if not passed fallsback to ENV['CLIENT_ID']
    # @option options[:client_secret] [String] - Client Secret, if not passed fallsback to ENV['CLIENT_SECRET']
    # @option options[:redirect_uri] [String] - Redirect URI, if not passed fallsback to ENV['REDIRECT_URI']
    # @option options[:state] [String] - OAuth state parameter passed to the
    # redirect uri. This parameter may be used for identifying the user who
    # initiated the request.
    # @option options[:test_mode] [Boolean] - Setting this to 'true' runs it in test mode.
    # @option options[:force_prompt] [Boolean] - Setting `force_prompt` to
    # `true` will show the permissions approval screen on every authentication
    # attempt, even if the user has previously consented to the exact scope of
    # permissions.
    # @option options[:make] [String] - `make' is an optional parameter that allows
    # users to bypass the car brand selection screen.
    # For a complete list of supported makes, please see our
    # [API Reference](https://smartcar.com/docs/api#authorization) documentation.
    # @option options[:scope] [Array of Strings] - array of scopes that specify what the user can access
    #   EXAMPLE : ['read_odometer', 'read_vehicle_info', 'required:read_location']
    # For further details refer to https://smartcar.com/docs/guides/scope/
    #
    # @return [Smartcar::Oauth] Returns a Smartcar::Oauth Object that has other methods
    def initialize(options)
      @redirect_uri = options[:redirect_uri] || get_config('REDIRECT_URI')
      @client_id = options[:client_id] || get_config('CLIENT_ID')
      @client_secret = options[:client_secret] || get_config('CLIENT_SECRET')

      @auth_parameters = {
        redirect_uri: @redirect_uri,
        approval_prompt: options[:force_prompt] ? FORCE : AUTO,
        mode: options[:test_mode] ? TEST : LIVE,
        response_type: CODE
      }
      @auth_parameters[:scope] = options[:scope].join(' ') if options[:scope]
      %I(state make).each do |parameter|
        parameters[:parameter] = options[:parameter] unless options[:parameter].nil?
      end
    end

    # Generate the OAuth authorization URL.
    #
    # @return [String] Authorization URL string
    def authorization_url
      client.auth_code.authorize_url(@auth_parameters)
    end

    # Generates the tokens hash using the code returned in oauth process.
    # @param auth_code [String] This is the code that is returned after user
    # visits and authorizes on the authorization URL.
    #
    # @return [Hash] Hash of token, refresh token, expiry info and token type
    def get_token(auth_code)
      client.auth_code
        .get_token(
          auth_code,
          redirect_uri: @redirect_uri
        ).to_hash
    end

    # Refreshing the access token
    # @param token_hash [Hash] This is the hash that is returned with the
    # get_token method
    #
    # @return [Hash] Hash of token, refresh token, expiry info and token type
    def refresh_token(token_hash)
      token_object = OAuth2::AccessToken.from_hash(client, token_hash)
      token_object = token_object.refresh!
      token_object.to_hash
    end

    private
    # gets the Oauth Client object
    #
    # @return [OAuth2::Client] A Oauth Client object.
    def client
      @client ||= OAuth2::Client.new( @client_id,
        @client_secret,
        :site => OAUTH_PATH
      )
    end
  end
end
