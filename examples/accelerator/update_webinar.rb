# frozen_string_literal: true

require 'rowan_bot'

tasks = RowanBot::Tasks.new

tasks.salesforce_api = RowanBot::SalesforceAPI.new
tasks.zoom_api = RowanBot::ZoomAPI.new

program_id = ''
tasks.assign_zoom_links_for_lcs(program_id)
tasks.assign_zoom_links_for_fellows(program_id)
