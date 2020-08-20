# frozen_string_literal: true

require 'rowan_bot'

tasks = RowanBot::Tasks.new
tasks.salesforce_api = RowanBot::SalesforceAPI.new
tasks.slack_api = RowanBot::SlackAPI.new

admin_emails = ENV.fetch('SLACK_ADMIN_EMAILS', '').split(',').map(&:strip)

emails = []

tasks.assign_to_booster_run_channels_in_slack(emails, admin_emails)
tasks.assign_to_booster_peer_group_channel_in_slack(emails, admin_emails)
