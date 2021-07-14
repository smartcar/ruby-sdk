# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smartcar/version'

Gem::Specification.new do |spec|
  spec.name = 'smartcar'
  spec.version = Smartcar::VERSION
  spec.required_ruby_version = '>= 2.5.0'
  spec.authors = ['Ashwin Subramanian']
  spec.email = ['ashwin.subramanian@smartcar.com']
  spec.homepage = 'https://rubygems.org/gems/smartcar'
  spec.summary = 'Ruby Gem to access smartcar APIs (https://smartcar.com/docs/)'
  spec.description = 'This is a ruby gem to access the smartcar APIs. It includes the API classes and the OAuth system.'
  spec.license = 'MIT'
  spec.metadata = {
    'source_code_uri' => 'https://github.com/smartcar/ruby-sdk',
    'documentation_uri' => 'https://www.rubydoc.info/gems/smartcar'
  }
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'byebug', '~> 11.0'
  spec.add_development_dependency 'codecov', '~> 0.5.2'
  spec.add_development_dependency 'rake', '~> 12.3', '>= 12.3.3'
  spec.add_development_dependency 'readapt', '~> 1.3'
  spec.add_development_dependency 'redcarpet', '~> 3.5.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.12'
  spec.add_development_dependency 'selenium-webdriver', '~> 3.142'
  spec.add_development_dependency 'webmock', '~> 3.13'
  spec.add_dependency 'oauth2', '~> 1.4'
  spec.add_dependency 'recursive-open-struct', '~> 1.1.3'
end
