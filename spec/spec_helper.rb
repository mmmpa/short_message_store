ENV['ENV'] = 'test'

require 'pathname'
require Pathname(__dir__) + '../requirement'
require 'rspec'
require 'factory_girl'
require 'rspec-html-matchers'
require 'simplecov'
require 'simplecov-rcov'
require 'pathname'

=begin
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start 'rails' do
  add_filter '/lib/'
  add_filter '/spec/'
end
=end


RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = :random
  config.include RSpecHtmlMatchers
  config.include FactoryGirl::Syntax::Methods

  config.before :all do
    FactoryGirl.reload
    FactoryGirl.factories.clear
    FactoryGirl.sequences.clear
    FactoryGirl.find_definitions
  end
end
