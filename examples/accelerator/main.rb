require 'yaml'
require 'csv'
require 'rowan_bot'

# Read zoom token from file
user_id = File.read('user_id.txt').chomp
meeting_details = YAML.load_file('meeting.yaml')
participants = CSV.read('participants.csv', headers: true).map(&:to_h)

tasks = RowanBot::Tasks.new(RowanBot::ZoomAPI.new)

# Use this to create a meeting
meeting = tasks.create_weekly_zoom_meeting(user_id, meeting_details)

# You can replace with a meeting id and comment out line 14
# meeting_id = 83_005_867_157
meeting_id = meeting['id']

registrants = tasks.add_participants_to_meetings(meeting_id, participants)

CSV.open('meeting_participants.csv', 'w') do |csv|
  csv << registrants.first.keys
  registrants.each { |registrant| csv << registrant.values }
end
