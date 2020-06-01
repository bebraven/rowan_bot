namespace :sync do
  desc 'Updates Salesforce to indicate who has signed their DocuSign waivers.'
  task :docusign_to_salesforce do
    puts "### the sync_docusign_to_salesforce task is running"
    puts "### SALESFORCE_PLATFORM_USERNAME = #{ENV['SALESFORCE_PLATFORM_USERNAME']} "
  end
end
