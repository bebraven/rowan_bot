# frozen_string_literal: true

require 'rowan_bot'

tasks = RowanBot::Tasks.new
tasks.docusign_api = RowanBot::DocuSignAPI.new
tasks.salesforce_api = RowanBot::SalesforceAPI.new
tasks.slack_api = RowanBot::SlackAPI.new
emails = tasks.sync_signed_waivers_to_salesforce(30)
tasks.assign_slack_to_users(emails)
tasks.assign_peer_groups_to_users(emails)
