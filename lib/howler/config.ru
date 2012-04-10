require File.expand_path('../web', __FILE__)
require 'multi_json'

Howler::Config[:path_prefix] = '/'

run Howler::Web
