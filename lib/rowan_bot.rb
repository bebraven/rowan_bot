require 'logger'
require 'rowan_bot/version'
require 'rowan_bot/zoom_api'
require 'rowan_bot/salesforce_api'
require 'rowan_bot/tasks'

module RowanBot
  class Error < StandardError; end

  # We'll log to STDOUT for now since we're only using it in the terminal for
  # now
  @logger = Logger.new(STDOUT)

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end
