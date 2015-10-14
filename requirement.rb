require 'pathname'
require Pathname(__dir__) + 'config/initializers/common_constants'
require 'redis'
require 'redis-namespace'
require 'redis-objects'
require 'twitter'
require 'dotenv'
require 'active_support'
require 'active_support/core_ext'
require 'sinatra'
require 'sinatra/cookies'
require 'sinatra/reloader' if development?
require 'slim'
require 'slim/include'

Dotenv.load

Dir[
  Common::ROOT + 'config/initializers/**/*.rb',
  Common::ROOT + 'app/**/*.rb',
  Common::ROOT + 'spec/supports/**/*.rb'
].each(&method(:require))
