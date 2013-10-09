# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git/browse/remote/version'

Gem::Specification.new do |spec|
  spec.name          = "git-browse-remote"
  spec.version       = Git::Browse::Remote::VERSION
  spec.authors       = ["motemen"]
  spec.email         = ["motemen@gmail.com"]
  spec.summary       = 'Open web browser to view remote Git repositories'
  spec.homepage      = 'https://github.com/motemen/git-browse-remote'
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec', '~> 2'
  spec.add_development_dependency 'simplecov', '0.7.1'
  spec.add_development_dependency 'guard', '~> 1'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'terminal-notifier-guard'
end
