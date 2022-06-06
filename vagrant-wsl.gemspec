# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-wsl/version'

Gem::Specification.new do |gem|
  gem.name          = 'vagrant-wsl'
  gem.homepage      = 'https://github.com/aracpac/vagrant-wsl'
  gem.metadata      = { 'source_code_uri'  => 'https://github.com/aracpac/vagrant-wsl' }
  gem.version       = VagrantPlugins::ProviderWSL::VERSION
  gem.authors       = ['Mo Ismailzai', 'AracPac']
  gem.email         = %w[mo@ismailzai.com info@aracpac.com]
  gem.description   = %q{Enables Vagrant to manage machines in WSL.}
  gem.summary       = gem.description
  gem.license       = 'MIT'

  gem.required_rubygems_version = ">= 1.3.6"

  gem.add_runtime_dependency "iniparse", "~> 1.4", ">= 1.4.2"

  gem.add_development_dependency "rake"
  # rspec 3.4 to mock File
  gem.add_development_dependency "rspec", "~> 3.4"
  gem.add_development_dependency "rspec-its"

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
end