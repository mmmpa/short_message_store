require 'pathname'
require Pathname(__dir__) + 'config/initializers/common_constants'
require 'redis'
require 'redis-namespace'
require 'redis-objects'
require 'dotenv'
require 'active_support'
require 'active_support/core_ext'
require 'mail'
require 'sinatra'
require 'sinatra/cookies'
require 'sinatra/reloader' if development?
require 'slim'
require 'slim/include'
require 'coffee_script'
require 'sass'
require 'pp'

Dotenv.load

Dir[
  Common::ROOT + 'config/initializers/**/*.rb',
  Common::ROOT + 'app/**/*.rb',
  Common::ROOT + 'spec/supports/**/*.rb'
].each(&method(:require))
