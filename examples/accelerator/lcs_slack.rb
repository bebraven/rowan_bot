# frozen_string_literal: true

require 'rowan_bot'

tasks = RowanBot::Tasks.new

salesforce_api = RowanBot::SalesforceAPI.new
tasks.zoom_api = RowanBot::ZoomAPI.new
tasks.salesforce_api = salesforce_api

program_id = ''
participants = salesforce_api.all_participants(program_id, 'Leadership_Coach')
p participants.size

signed_waivers = participants.filter(&:signed_waiver_complete)
p signed_waivers.size
puts signed_waivers.map(&:email).join(',')

puts '#' * 10
cps = signed_waivers.filter { |p| p.coaching_partner_role.eql?('Coach Partner') }
p cps.size
puts cps.map(&:email).join(',')
