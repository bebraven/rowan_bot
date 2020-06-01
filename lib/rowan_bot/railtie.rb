class RowanBot::Railtie < Rails::Railtie
  rake_tasks do
    load 'tasks/sync_docusign_to_salesforce.rake'
  end
end
