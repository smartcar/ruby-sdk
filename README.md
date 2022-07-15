
# Smartcar Ruby SDK [![Gem Version][gem-url]][gem-image]

Ruby gem library to quickly get started with the Smartcar API.

## Overview

The [Smartcar API](https://smartcar.com/docs) lets you read vehicle data
(location, odometer) and send commands to vehicles (lock, unlock) using HTTP requests.

To make requests to a vehicle from a web or mobile application, the end user
must connect their vehicle using
[Smartcar Connect](https://smartcar.com/docs/api#smartcar-connect).
This flow follows the OAuth spec and will return a `code` which can be used to
obtain an access token from Smartcar.

The Smartcar Ruby Gem provides methods to:

1. Generate the link to redirect to Connect.
2. Make a request to Smartcar with the `code` obtained from Connect to obtain an
   access and refresh token
3. Make requests to the Smartcar API to read vehicle data and send commands to
   vehicles using the access token obtained in step 2.

Before integrating with Smartcar's SDK, you'll need to register an application
in the [Smartcar Developer portal](https://developer.smartcar.com). If you do
not have access to the dashboard, please
[request access](https://smartcar.com/subscribe).

### Flow

- Create a new `AuthClient` object with your `client_id`, `client_secret`,
  `redirect_uri`.
- Redirect the user to Smartcar Connect using `get_auth_url` with required `scope` or with one
  of our frontend SDKs.
- The user will login, and then accept or deny your `scope`'s permissions.
- Handle the get request to `redirect_uri`.
  - If the user accepted your permissions, `req.query.code` will contain an
    authorization code.
    - Use `exchange_code` with this code to obtain an access object
      containing an access token (lasting 2 hours) and a refresh token
      (lasting 60 days).
      - Save this access object.
    - If the user denied your permissions, `req.query.error` will be set
      to `"access_denied"`.
    - If you passed a state parameter to `get_auth_url`, `req.query.state` will
      contain the state value.
- Get the user's vehicles with `getVehicles`.
- Create a new `Vehicle` object using a `vehicle_id` from the previous response,
  and the `access_token`.
- Make requests to the Smartcar API.
- Use `exchange_refresh_token` on your saved `refresh_token` to retrieve a new token
  when your `access_token` expires.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'smartcar'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install smartcar

## Usage

Setup the environment variables for SMARTCAR_CLIENT_ID, SMARTCAR_CLIENT_SECRET and SMARTCAR_REDIRECT_URI.
```bash
# Get your API keys from https://dashboard.smartcar.com/signup
export SMARTCAR_CLIENT_ID=<client id>
export SMARTCAR_CLIENT_SECRET=<client secret>
export SMARTCAR_REDIRECT_URI=<redirect URI>
```

Example Usage for calling the reports API with oAuth token
```ruby
2.5.7 :001 > require 'smartcar'
 => true
2.5.7 :003 > ids =  Smartcar.get_vehicles(token: token).vehicles
 => ["4bb777b2-bde7-4305-8952-25956f8c0868"]
2.5.7 :004 > vehicle = Smartcar::Vehicle.new(token: token, id: ids.first)
 => #<Smartcar::Vehicle:0x0000558dcd7ee608 @token="c900e00e-ee8e-403d-a7bf-f992bc0ad302", @id="e31c9de6-1332-472b-b648-5d74b05b7fda", @options={:unit_system=>"metric", :version=>"2.0"}, @unit_system="metric", @version="2.0", @service=#<Faraday::Connection:0x0000558dcd7d63f0 @parallel_manager=nil, @headers={"User-Agent"=>"Faraday v1.4.2"}, @params={}, @options=#<Faraday::RequestOptions timeout=310>, @ssl=#<Faraday::SSLOptions verify=true>, @default_parallel_manager=nil, @builder=#<Faraday::RackBuilder:0x0000558dcd7c1bf8 @adapter=Faraday::Adapter::NetHttp, @handlers=[Faraday::Request::UrlEncoded], @app=#<Faraday::Request::UrlEncoded:0x0000558dcd7af048 @app=#<Faraday::Adapter::NetHttp:0x0000558dcd7af390 @ssl_cert_store=#<OpenSSL::X509::Store:0x0000558dcd7a36a8 @verify_callback=nil, @error=nil, @error_string=nil, @chain=nil, @time=nil>, @app=#<Proc:0x0000558dcd7af278 /home/ashwinsubramanian/.rvm/gems/ruby-2.7.2/gems/faraday-1.4.2/lib/faraday/adapter.rb:37 (lambda)>, @connection_options={}, @config_block=nil>, @options={}>>, @url_prefix=#<URI::HTTPS https://api.smartcar.com/>, @proxy=nil, @manual_proxy=false>>
2.5.7 :006 > vehicle.odometer
 => #<OpenStruct distance=39685.33984375, meta=#<OpenStruct data_age=#<DateTime: 2021-06-24T22:28:39+00:00 ((2459390j,80919s,95000000n),+0s,2299161j)>, unit_system="metric", request_id="4962ba7f-5c94-48ab-9955-4e2b101c7b8a">>
2.5.7 :007 > vehicle.battery
 => #<OpenStruct range=208.82, percentRemaining=0.31, meta=#<OpenStruct data_age=#<DateTime: 2021-06-24T22:28:54+00:00 ((2459390j,80934s,855000000n),+0s,2299161j)>, unit_system="metric", request_id="a88b95ec-b10f-4fc8-979b-5d95fe40d925">, percentage_remaining=0.31>
2.5.7 :009 > vehicle.lock!
 => #<OpenStruct status="success", message="Successfully sent request to vehicle", meta=#<OpenStruct request_id="0c90918f-a9cc-405c-839f-7d9b70e249c4">>
2.5.7 :010 > batch_response = vehicle.batch(["/charge","/battery"])
=> #<OpenStruct>
2.5.7 :011 > batch_response.charge()
=> #<OpenStruct state="NOT_CHARGING", isPluggedIn=false, meta=#<OpenStruct data_age=#<DateTime: 2021-06-24T22:30:20+00:00 ((2459390j,81020s,892000000n),+0s,2299161j)>, request_id="29a66280-8685-4a57-9733-daa3dfb9970f">, is_plugged_in?=false>
```

Example Usage for oAuth -
```ruby
# To get the redirect URL :
2.5.5 :002 > options = {mode: 'test'}
2.5.5 :003 > require 'smartcar'
2.5.5 :004 > client = Smartcar::AuthClient.new(options)
2.5.5 :005 > url = client.get_auth_url(["read_battery","read_charge","read_fuel","read_location","control_security","read_odometer","read_tires","read_vin","read_vehicle_info"], {flags: ["country:DE"]})
 => "https://connect.smartcar.com/oauth/authorize?approval_prompt=auto&client_id=<client id>&mode=test&redirect_uri=http%3A%2F%2Flocalhost%3A8000%2Fcallback&response_type=code&scope=read_battery+read_charge+read_fuel+read_location+control_security+read_odometer+read_tires+read_vin+read_vehicle_info&flags=country%3ADE"
# Redirect user to the above URL.
# After authentication user control reaches the callback URL with code.
# Use the code from the parameters and request a token
2.5.5 :006 > token_hash = client.exchange_code(code)
 => #<OpenStruct token_type="Bearer", access_token="20e24b4a-3055-4cc8-9cf3-2b3c5afba3e6", refresh_token="cf89c62e-7b36-4e13-a9df-d9c2a5296280", expires_at=1624581588>
# This access_token can be used to call the Smartcar APIs as given above.
# Store this hash and if it expired refresh the token OR use the code again to
# get a new token or use .
```

## Advanced configuration

This SDK uses the [Faraday HTTP client library](https://lostisland.github.io/faraday/) which supports extensive customization through the use of middleware. If you need to customize the behavior of HTTP request/response processing, you can provide your own instance of Faraday::Connection to most methods in this library.

**Important:** If you provide your own Faraday connection, you are responsible for configuring all HTTP connection behavior, including timeouts! This SDK uses some custom timeouts internally to ensure best behavior by default, so unless you want to customize them you may want to replicate those timeouts.

Example of providing a custom Faraday connection to various methods:
```ruby
  # Example Faraday connection that uses the Instrumentation middleware
  service = Faraday::Connection.new(url: Smartcar::API_ORIGIN, request: { timeout: Smartcar::DEFAULT_REQUEST_TIMEOUT }) do |c|
    c.request :instrumentation
  end

  # Passing the custom service to #get_vehicles
  Smartcar.get_vehicles(token: token, options: { service: service })

  # Passing the custom service to #get_user
  Smartcar.get_user(token: token, options: { service: service })

  # Passing the custom service to #get_compatibility
  Smartcar.get_compatibility(vin: vin, scope: scope, options: { service: service })

  # Passing the custom service into a Smartcar::Vehicle object
  vehicle = Smartcar::Vehicle.new(token: token, id: id, options: { service: service })
```

## Development

To install this gem onto your local machine, run `bundle exec rake install`.

To run tests, make sure you have the env variables setup for client id and secret.
```shell
export E2E_SMARTCAR_CLIENT_ID=<client id>
export E2E_SMARTCAR_CLIENT_SECRET=<client secret>
export E2E_SMARTCAR_AMT=<amt from dashboard for webhooks>
export E2E_SMARTCAR_WEBHOOK_ID=<webhook id to use for tests>
```

Tests can be run using either default rake command OR specific rspec command.
```
bundle exec rake spec
```

**NOTE : Do not forget to update the version number in version.rb.**

## Release

Deployments to Rubgygems is automated through Travis. After merging to master, create a tag on the latest commit on master and push it. That would trigger a CI job which will build, test and deploy to Rubygems. As a convention we use the version number of the gem for the release tag.

```
# After merging to master, checkout to master and pull code locally, then run the following
git tag v1.2.3
# now push the tags
git push origin --tags
Total 0 (delta 0), reused 0 (delta 0)
To github.com:smartcar/ruby-sdk.git
 * [new tag]         v1.2.3 -> v1.2.3
```


## Contributing

To contribute, please:

1. Open an issue for the feature (or bug) you would like to resolve.
2. Resolve the issue and add tests in your feature branch.
3. Open a PR from your feature branch into `master` that tags the issue.

[gem-image]: https://badge.fury.io/rb/smartcar
[gem-url]: https://badge.fury.io/rb/smartcar.svg

## Supported Ruby Branches

Smartcar aims to support the SDK on all Ruby branches that have a status of "normal maintenance" or "security maintenance" as defined in the [Ruby Branches documentation](https://www.ruby-lang.org/en/downloads/branches/).

In accordance with the Semantic Versioning specification, the addition of support for new Ruby branches would result in a MINOR version bump and the removal of support for Ruby branches would result in a MAJOR version bump.
