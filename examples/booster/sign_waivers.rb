# frozen_string_literal: true

require 'rowan_bot'

tasks = RowanBot::Tasks.new
tasks.docusign_api = RowanBot::DocuSignAPI.new
tasks.salesforce_api = RowanBot::SalesforceAPI.new
tasks.slack_api = RowanBot::SlackAPI.new
tasks.zoom_api = RowanBot::ZoomAPI.new

emails = tasks.sync_booster_signed_waivers_to_salesforce(1)

unless emails.empty?
  tasks.assign_peer_groups_to_booster_users(emails)
  tasks.assign_zoom_links_to_booster_participants(emails)
end
tasks.send_onboarding_notification(emails)
