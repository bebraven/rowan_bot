require 'rowan_bot'

tasks = RowanBot::Tasks.new
tasks.docusign_api = RowanBot::DocuSignAPI.new
tasks.salesforce_api = RowanBot::SalesforceAPI.new
tasks.sync_signed_waivers_to_salesforce
 
