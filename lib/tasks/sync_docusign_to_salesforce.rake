namespace :sync do
  desc 'Updates Salesforce to indicate who has signed their DocuSign waivers.'
  task :docusign_to_salesforce do

    puts "### The sync_docusign_to_salesforce task is running"

    docusign_api = RowanBot::DocuSignAPI.new()
    docusign_api.list_envelopes

    # Hardcoding a test here for now. We need to implement this method to go to DocuSign,
    # get all the signed envelopes, and call this in a loop to set the waiver field for each.
    salesforce_api = RowanBot::SalesforceAPI.new()
    salesforce_api.set_student_waiver_field('brian+testbooster10@bebraven.org', true) 

  end
end
