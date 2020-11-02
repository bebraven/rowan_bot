# frozen_string_literal: true

require 'rowan_bot'

tasks = RowanBot::Tasks.new

tasks.salesforce_api = RowanBot::SalesforceAPI.new
tasks.zoom_api = RowanBot::ZoomAPI.new

program_id = ''
tasks.sync_zoom_links_for_program(program_id, true)
