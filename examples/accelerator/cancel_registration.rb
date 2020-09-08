# frozen_string_literal: true

require 'csv'
require 'rowan_bot'

participants = CSV.read('participants.csv', headers: true).map(&:to_h)

tasks = RowanBot::Tasks.new(RowanBot::ZoomAPI.new)

# meeting_id = 83_005_867_157
meeting_id = ''

tasks.cancel_registrants_from_meeting(meeting_id, participants)

puts '##### All Done! ####'
