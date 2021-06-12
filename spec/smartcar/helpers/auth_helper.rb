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
           'required:read_tires'].freeze

  class << self
    def get_code(uri)
      code_hash = CGI.parse(URI.parse(uri).query)
      code_hash['code'].first
    end

    def auth_client_params
      {
        redirect_uri: 'https://example.com/auth',
        test_mode: true
      }
    end

    def run_auth_flow(authorization_url, test_email = nil)
      email = test_email || "#{SecureRandom.uuid}@email.com"
      options = Selenium::WebDriver::Firefox::Options.new(args: ['-headless'])
      driver = Selenium::WebDriver.for :firefox, options: options
      driver.navigate.to authorization_url
      driver.find_element(css: 'button#continue-button').click
      driver.find_element(css: 'button.brand-selector-button[data-make="CHEVROLET"]').click
      driver.find_element(css: 'input[id=username]').send_keys(email)
      driver.find_element(css: 'input[id=password').send_keys('password')
      driver.find_element(css: 'button[id=sign-in-button]').click

      wait = Selenium::WebDriver::Wait.new(timeout: 3)

      wait.until do
        element = driver.find_element(:css, 'button[id=approval-button]')
        element if element.displayed?
      end.click

      uri = wait.until do
        driver.current_url if driver.current_url.match('example.com')
      end
      driver.quit
      get_code(uri)
    end

    def run_auth_flow_and_get_tokens(test_email = nil)
      client = Smartcar::AuthClient.new(auth_client_params)
      authorization_url = client.get_auth_url(SCOPE, { force_prompt: true })
      code = run_auth_flow(authorization_url, test_email)
      client.exchange_code(code)
    end
  end
end
