# frozen_string_literal: true

namespace :sync do
  desc 'Updates Salesforce to indicate who has signed their DocuSign waivers.'
  task :docusign_to_salesforce do
    days = ARGV[1] ? ARGV[1].to_i : 1

    tasks = RowanBot::Tasks.new
    tasks.docusign_api = RowanBot::DocuSignAPI.new
    tasks.salesforce_api = RowanBot::SalesforceAPI.new
    tasks.sync_signed_waivers_to_salesforce(days)
  end
end
