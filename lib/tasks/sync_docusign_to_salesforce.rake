# frozen_string_literal: true

namespace :sync do
  desc 'Updates Salesforce to indicate who has signed their DocuSign waivers.'
  task :docusign_to_salesforce do
    days = ARGV[1] ? ARGV[1].to_i : 1

    tasks = RowanBot::Tasks.new
    tasks.docusign_api = RowanBot::DocuSignAPI.new
    tasks.salesforce_api = RowanBot::SalesforceAPI.new
    emails = tasks.sync_signed_waivers_to_salesforce(days)

    # I'll tag these tasks here since they depend on emails of people who
    # recently signed
    tasks.assign_slack_to_users(emails)
    tasks.assign_peer_groups_to_users(emails)
    tasks.assign_to_peer_group_channel_in_slack(emails, ['abdulmajid.hamza@bebraven.org', 'aleks.calderon@bebraven.org'])
  end
end
