# frozen_string_literal: true

namespace :sync do
  desc 'Updates Salesforce to indicate who has signed their DocuSign waivers.'
  task :docusign_to_salesforce, [:days] do |_, args|
    days = args[:days] ? args[:days].to_i : 1

    tasks = RowanBot::Tasks.new
    tasks.docusign_api = RowanBot::DocuSignAPI.new
    tasks.salesforce_api = RowanBot::SalesforceAPI.new
    tasks.slack_api = RowanBot::SlackAPI.new
    tasks.zoom_api = RowanBot::ZoomAPI.new
    emails = tasks.sync_signed_waivers_to_salesforce(days)

    # I'll tag these tasks here since they depend on emails of people who
    # recently signed
    unless emails.empty?
      admin_emails = ENV.fetch('SLACK_ADMIN_EMAILS', '').split(',').map(&:strip)
      tasks.assign_slack_to_users(emails)
      tasks.assign_peer_groups_to_users(emails)
      sleep(5) # Slack seems to take a sec before it can find the users added above
      tasks.assign_to_peer_group_channel_in_slack(emails, admin_emails)
      tasks.assign_zoom_links_to_users(emails)
      tasks.send_onboarding_notification(emails)
    end
  end
end
