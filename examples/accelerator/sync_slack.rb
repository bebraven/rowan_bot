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

participants = salesforce_api.all_participants(program.id, 'Fellow').filter { |participant| participant.status.eql?('Enrolled') }

def cohort_channel_name(participant)
  day = participant.peer_group.split[1]
  first_name = participant.peer_group_lc_name.scan(/\w+/)
  last_name = participant.peer_group_lc_last_name.gsub(/\w+/)
  ['cohort', day, *first_name, *last_name].join('-').downcase
end

has_cohort = participants.filter { |participant| !participant.peer_group.nil? }
x = has_cohort.inject({}) do |acc, parts|
  channel = cohort_channel_name(parts)
  if acc[channel].nil?
    acc[channel] = [parts.email]
  else
    acc[channel] << parts.email
  end
  acc
end


slack_channels = slack_api.create_peer_group_channels(x.keys).first
slack_channels = slack_channels.inject({}) do |acc, chan|
  acc[chan[:name]] = chan[:id]
  acc
end

current_pairing = {}
slack_channels.each do |channel, channel_id|
  mems = slack_api.get_channel_members(channel_id)
  mems.each do |mem|
    current_pairing[mem] = { name: channel, id: channel_id }
  end
end

x.each do |cohort_name, emails|
  pts = emails.map { |email| { email: email } }
  slack_users = slack_api.add_slack_ids_to_users(pts)
  slack_admin_users = slack_api.add_slack_ids_to_users(slack_admins)
  to_add = slack_admin_users.map { |u| u[:slack_id] }
  slack_users.each do |sl_u|
    sl_id = sl_u[:slack_id]
    if current_pairing[sl_id].nil?
      to_add << sl_id
    elsif !current_pairing[sl_id][:name].eql?(cohort_name)
      to_add << sl_id
      slack_api.remove_user_from_channel(current_pairing[sl_id][:id], sl_id)
    end
  end
  slack_api.add_users_to_peer_group_channel(slack_channels[cohort_name], to_add)
end
