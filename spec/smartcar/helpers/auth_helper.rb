# frozen_string_literal: true

require_relative '../../../lib/smartcar'
require 'selenium-webdriver'
require 'securerandom'
require 'cgi'

class AuthHelper
  SCOPE = ['required:read_vehicle_info',
           'required:read_location',
           'required:read_odometer',
           'required:control_security',
           'required:read_vin',
           'required:read_fuel',
           'required:read_battery',
           'required:read_charge',
           'required:read_engine_oil',
           'required:read_tires',
           'required:read_service_history',
           'required:read_security'].freeze

  class << self
    def get_code(uri)
      code_hash = CGI.parse(URI.parse(uri).query)
      code_hash['code'].first
    end

    def auth_client_params
      {
        redirect_uri: 'https://example.com/auth',
        mode: 'test'
      }
    end

    def run_auth_flow(authorization_url, test_email = nil, make = nil)
      email = test_email || "#{SecureRandom.uuid}@email.com"
      make ||= 'CHEVROLET'
      headless_mode = ENV['HEADLESS'] == 'false' ? [''] : ['-headless']
      options = Selenium::WebDriver::Firefox::Options.new(args: headless_mode)
      driver = Selenium::WebDriver.for(:firefox, capabilities: [options])
      driver.navigate.to authorization_url
      driver.manage.timeouts.implicit_wait = 10
      driver.find_element(css: "button##{make}.brand-list-item").click
      driver.find_element(css: 'input[id=username]').send_keys(email)
      driver.find_element(css: 'input[id=password').send_keys('password')
      driver.find_element(css: 'button[id=sign-in-button]').click
      wait = Selenium::WebDriver::Wait.new(timeout: 60)
      %w[approval-button].each do |button|
        wait.until do
          element = driver.find_element(:css, "button[id=#{button}]")
          element if element.displayed?
        end.click
      rescue Selenium::WebDriver::Error::TimeoutError
        # Adding this for when continue-button is back again
      end

      uri = wait.until do
        driver.current_url if driver.current_url.match('example.com')
      end

      driver.quit
      get_code(uri)
    end

    def run_auth_flow_and_get_tokens(test_email = nil, make = nil, scope = SCOPE)
      client = Smartcar::AuthClient.new(auth_client_params)
      authorization_url = client.get_auth_url(scope, { force_prompt: true })
      code = run_auth_flow(authorization_url, test_email, make)
      client.exchange_code(code)
    end
  end
end
