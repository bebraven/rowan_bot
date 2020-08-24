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
        { **participant, 'join_url' => response['join_url'] }
      end
    end

    def create_weekly_zoom_meeting(user_id, meeting_details)
      logger.info('Started creating weekly meeting')
      zoom_api.create_meeting(user_id, meeting_details)
    end

    def sync_booster_signed_waivers_to_salesforce(days = 1)
      logger.info('Started syncing waiver details to salesforce')
      signed_emails = docusign_api.recently_signed_emails(days)
      return [] if signed_emails.empty?

      record_type = 'Booster_Student'
      salesforce_api.find_participants_by_emails(signed_emails, record_type)
      salesforce_api.sign_participants_waivers_by_email(signed_emails, record_type)
    end

    def assign_peer_groups_to_booster_users(emails)
      logger.info("Started assigning peer groups to users: #{emails}")
      salesforce_api.assign_peer_groups_to_user_emails(emails, 'Booster_Student')
    end

    def assign_slack_to_users(emails)
      logger.info("Started assigning slack to users: #{emails}")
      slack_api.invite_users_to_slack(emails)
    end

    def assign_zoom_links_for_fellows(program_id)
      record_type = 'Fellow'
      emails = salesforce_api.all_participants(program_id, record_type).map(&:email)
      assign_zoom_links_to_participants(emails, record_type)
    end

    def assign_zoom_links_for_lcs(program_id)
      record_type = 'Leadership_Coach'
      emails = salesforce_api.all_participants(program_id, record_type).map(&:email)
      assign_zoom_links_to_participants(emails, record_type)
    end

    def assign_zoom_links_to_booster_participants(emails)
      assign_zoom_links_to_participants(emails, 'Booster_Student')
    end

    def assign_zoom_links_to_participants(emails, record_type)
      logger.info("Started assigning zoom links to users: #{emails}")
      emails.each do |email|
        participant = salesforce_api.find_participant_by_email(email, record_type)
        registration_details = {
          'email' => participant.email,
          'first_name' => participant.first_name,
          'last_name' => participant.last_name
        }
        join_url1 = nil
        join_url2 = nil
        if !participant.webinar_registration_1.nil? && participant.webinar_link_1.nil?
          join_url1 = zoom_api.add_registrant(
            participant.webinar_registration_1,
            registration_details
          )['join_url']
        end

        if !participant.webinar_registration_2.nil? && participant.webinar_link_2.nil?
          join_url2 = zoom_api.add_registrant(
            participant.webinar_registration_2,
            registration_details
          )['join_url']
        end

        if join_url1.nil? && join_url2.nil?
          logger.warn("Skipping #{participant.email}")
        else
          salesforce_api.update_participant_webinar_links(participant.id, join_url1, join_url2)
          logger.info("Added zoom link to: #{email}")
        end
      end
    end

    def send_onboarding_notification(emails)
      logger.info('Sending notification')
      slack_api.send_onboarding_notification(emails.join(', '))
    end

    def assign_to_channel_name_in_slack(emails, channel_name, admins)
      logger.info("Started assigning users to channel in slack #{channel_name}")
      admins = admins.map { |ad| { email: ad } }
      users = emails
              .map do |email|
                { email: email, peer_group: channel_name }
              end
      add_users_to_peer_group_channels(users, admins)
    end

    def assign_to_booster_peer_group_channel_in_slack(emails, admins)
      logger.info('Started assigning users to cohort channels in slack')
      admins = admins.map { |ad| { email: ad } }
      users = emails
              .map { |email| salesforce_api.find_participant_by_email(email, 'Booster_Student') }
              .map do |p|
                pname = p.peer_group.split.last(5)
                peer_group = ['peer', 'group', 'run', pname[0].to_i.to_s] + pname[1..-3]
                { email: p.email, peer_group: peer_group.join('-').downcase }
              end
      add_users_to_peer_group_channels(users, admins)
    end

    def assign_to_booster_run_channels_in_slack(emails, admins)
      logger.info('Started assigning users to run channels in slack')
      salesforce_api.find_participants_by_emails(emails, 'Booster_Student')
      admins = admins.map { |ad| { email: ad } }
      users = emails
              .map { |email| salesforce_api.find_participant_by_email(email, 'Booster_Student') }
              .map do |p|
                pname = p.peer_group.split.last(5)
                peer_group = ['run', pname[0].to_i.to_s, 'announcements']
                { email: p.email, peer_group: peer_group.join('-').downcase }
              end
      add_users_to_peer_group_channels(users, admins)
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
