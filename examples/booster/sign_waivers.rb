# frozen_string_literal: true

require 'rowan_bot'

tasks = RowanBot::Tasks.new
tasks.docusign_api = RowanBot::DocuSignAPI.new
tasks.salesforce_api = RowanBot::SalesforceAPI.new
tasks.slack_api = RowanBot::SlackAPI.new
tasks.zoom_api = RowanBot::ZoomAPI.new

admin_emails = ENV.fetch('SLACK_ADMIN_EMAILS', '').split(',').map(&:strip)

emails = tasks.sync_signed_waivers_to_salesforce(30)
tasks.assign_slack_to_users(emails)
tasks.assign_peer_groups_to_users(emails)
tasks.assign_to_peer_group_channel_in_slack(emails, admin_emails)
tasks.assign_zoom_links_to_users(emails)
tasks.send_onboarding_notification(emails)
