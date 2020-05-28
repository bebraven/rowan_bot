require 'yaml'
require 'csv'
require 'rowan_bot'

credentials = YAML.load_file('slack_secrets.yaml')
tasks = RowanBot::Tasks.new
tasks.slack_api = RowanBot::SlackAPI.new(credentials['token'])

users = CSV.read('participants_peer_groups.csv', headers: true).map(&:to_h)

# Transform peer group name
users = users.map do |user| 
  user['peer_group'] = user['peer_group'].split.last(2).join('-').downcase
  user
end

tasks.add_users_to_peer_group_channels(users)

