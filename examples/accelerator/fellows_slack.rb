# frozen_string_literal: true

require 'rowan_bot'

tasks = RowanBot::Tasks.new

salesforce_api = RowanBot::SalesforceAPI.new
tasks.zoom_api = RowanBot::ZoomAPI.new
tasks.salesforce_api = salesforce_api

program_id = ''
participants = salesforce_api.all_participants(program_id, 'Fellow')

p participants.size
with_portal_accounts = participants.filter { |p| !p.canvas_id.nil? }
p with_portal_accounts.size

puts with_portal_accounts.map(&:email).join(',')
