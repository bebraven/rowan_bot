require 'yaml'
require 'csv'
require 'rowan_bot'

credentials = YAML.load_file('slack_secrets.yaml')
tasks = RowanBot::Tasks.new
tasks.slack_api = RowanBot::SlackAPI.new(credentials['token'])

users = CSV.read('participants_peer_group.csv', headers: true).map(&:to_h)

tasks.add_users_to_peer_group_channels(users)

