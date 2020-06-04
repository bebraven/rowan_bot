# frozen_string_literal: true

module RowanBot
  # Tasks class for tasks to be done
  class Tasks
    attr_writer :zoom_api, :salesforce_api, :docusign_api, :slack_api
    # I do not want to break api
    def initialize(zoom_api = nil, salesforce_api = nil, docusign_api = nil, slack_api = nil)
      @zoom_api = zoom_api
      @salesforce_api = salesforce_api
      @docusign_api = docusign_api
      @slack_api = slack_api
    end

    def add_participants_to_meetings(meeting_id, participants)
      logger.info('Started adding participants')
      participants.map do |participant|
        response = zoom_api.add_registrant(meeting_id, participant)
        join_url = response['join_url']
        participant['join_url'] = join_url

        participant
      end
    end

    def create_weekly_zoom_meeting(user_id, meeting_details)
      logger.info('Started creating weekly meeting')
      zoom_api.create_meeting(user_id, meeting_details)
    end

    def sync_signed_waivers_to_salesforce(days = 1)
      logger.info('Started syncing waiver details to salesforce')
      signed_emails = docusign_api.recently_signed_emails(days)
      salesforce_api.sign_participants_waivers_by_email(signed_emails)
    end

    def assign_peer_groups_to_users(emails)
      logger.info("Started assigning peer groups to users: #{emails}")
      salesforce_api.assign_peer_groups_to_user_emails(emails)
    end

    def assign_slack_to_users(emails)
      logger.info("Started assigning slack to users: #{emails}")
      slack_api.invite_users_to_slack(emails)
    end

    def assign_zoom_links_to_users(emails)
      logger.info("Started assigning zoom links to users: #{emails}")
      emails.each do |email|
        participant = salesforce_api.find_participant_by_email(email)
        registration_details = { 'email' => participant.Contact__r.Email, 'first_name' => participant.Contact__r.Preferred_First_Name__c, 'last_name' => participant.Contact__r.Name }
        join_url_1 = zoom_api.add_registrant(participant.Cohort_Schedule__r.Webinar_Registration_1__c, registration_details)['join_url']
        join_url_2 = zoom_api.add_registrant(participant.Cohort_Schedule__r.Webinar_Registration_2__c, registration_details)['join_url']
        salesforce_api.update_participant_webinar_links(participant.Id, join_url_1, join_url_2)
        logger.info("Added zoom link to: #{email}")
      end
    end

    def send_onboarding_notification(emails)
      logger.info('Sending notification')
      slack_api.send_onboarding_notification(emails.join(', '))
    end

    def assign_to_peer_group_channel_in_slack(emails, admins)
      logger.info('Started assigning users to channels in slack')
      admins = admins.map { |ad| { email: ad } }
      users = salesforce_api
              .map_emails_with_peer_group(emails)
              .map { |u| { email: u[:email], peer_group: u[:peer_group].split.last(4).join('-').downcase } }
      add_users_to_peer_group_channels(users, admins)
    end

    def assign_peer_groups_to_program(program_id, cohort_size = 10)
      logger.info('Started assigning peer groups for program')
      salesforce_api.assign_peer_groups_to_program(program_id, cohort_size)
    end

    def add_users_to_peer_group_channels(users, admins = [])
      channel_names = users.map { |entry| entry[:peer_group] }.uniq
      channels, newly = slack_api.create_peer_group_channels(channel_names)
      admins_ids = slack_api.add_slack_ids_to_users(admins).map { |adms| adms[:slack_id] }
      transformed_users = slack_api.add_slack_ids_to_users(users)
      transformed_users = transformed_users.map do |t_user|
        channel = channels.find { |c| c[:name].eql?(t_user[:peer_group]) }
        t_user[:channel_id] = channel[:id]
        t_user
      end
      transformed = transformed_users.each_with_object({}) do |user, acc|
        if acc[user[:channel_id]].nil?
          acc[user[:channel_id]] = [user[:slack_id]]
        else
          acc[user[:channel_id]] << user[:slack_id]
        end
      end

      newly.each do |newl|
        slack_api.add_users_to_peer_group_channel(newl[:id], admins_ids)
      end
      # Add users
      transformed.each do |channel_id, user_ids|
        slack_api.add_users_to_peer_group_channel(channel_id, user_ids)
      end
    end

    private

    attr_reader :zoom_api, :salesforce_api, :docusign_api, :slack_api

    def logger
      RowanBot.logger
    end
  end
end
