require 'yaml'
require 'csv'
require 'rowan_bot'

# There should be a secrets.yaml in the same location as this file
credentials = YAML.load_file('secrets.yaml').transform_keys(&:to_sym)
tasks = RowanBot::Tasks.new
tasks.salesforce_api = RowanBot::SalesforceAPI.new(credentials)

# The id or the program to go through this
program_id = 'a2Y7A0000002BD1UAM'
# How big should a cohort be
cohort_size = 2

# Does the magic
pairings = tasks.assign_peer_groups_to_program(program_id, cohort_size)

# Save CSV file
CSV.open('participants_peer_groups.csv', 'w') do |csv|
  csv << pairings.first.keys
  pairings.each { |paring| csv << paring.values }
end
