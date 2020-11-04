require 'rowan_bot'

tasks = RowanBot::Tasks.new
salesforce_api = RowanBot::SalesforceAPI.new
tasks.salesforce_api = salesforce_api
program = salesforce_api.find_program_by_id('a2Y1J00000034NKUAY')
slack_api = RowanBot::SlackAPI.new({ slack_url: program.slack_url, slack_token:
                                    program.slack_token, slack_user: program.slack_user,
                                    slack_password: program.slack_password,
                                    slack_admin_emails: program.slack_admin_emails })
tasks.slack_api = slack_api
slack_admins = program.slack_admin_emails.split(',').map do |email|
  { email: email.strip }
end

tasks.sync_program_to_slack(program.id, slack_admins)