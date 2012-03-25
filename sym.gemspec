# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sym/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Brian Norton"]
  gem.email         = ["brian.nort@gmail.com"]
  gem.description   = gem.summary = "An Asynchronous Message Processing Library for Ruby"
  gem.homepage      = "http://github.com/bnorton/sym"

  #gem.executables   = ['sym']
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- spec/*`.split("\n")
  gem.name          = "sym"
  gem.require_paths = ["lib"]
  gem.version       = Sym::VERSION
  gem.add_dependency                  'redis'
  gem.add_dependency                  'celluloid'
  gem.add_dependency                  'connection_pool'
  gem.add_dependency                  'multi_json'
  gem.add_development_dependency      'rake'
  gem.add_development_dependency      'sinatra'
end
