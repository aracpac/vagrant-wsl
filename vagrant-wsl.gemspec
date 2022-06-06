# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-wsl/version'

Gem::Specification.new do |gem|
  gem.name          = 'vagrant-wsl'
  gem.version       = VagrantPlugins::WSL::VERSION
  gem.authors       = ['Mo Ismailzai']
  gem.email         = ['mo@ismailzai.com']
  gem.description   = %q{Enables Vagrant to manage machines in WSL.}
  gem.summary       = gem.description
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
end