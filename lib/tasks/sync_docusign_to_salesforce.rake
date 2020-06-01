namespace :sync do
  desc 'Updates Salesforce to indicate who has signed their DocuSign waivers.'
  task :docusign_to_salesforce do
    tasks = RowanBot::Tasks.new
    tasks.docusign_api = RowanBot::DocuSignAPI.new
    tasks.salesforce_api = RowanBot::SalesforceAPI.new
    tasks.sync_signed_waivers_to_salesforce
  end
end
