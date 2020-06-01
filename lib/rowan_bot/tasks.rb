module RowanBot
  # Tasks class for tasks to be done
  class Tasks
    attr_writer :zoom_api, :salesforce_api, :docusign_api
    # I do not want to break api
    def initialize(zoom_api = nil, salesforce_api = nil, docusign_api = nil)
      @zoom_api = zoom_api
      @salesforce_api = salesforce_api
      @docusign_api = docusign_api
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

    def sync_signed_waivers_to_salesforce
      logger.info('Started syncing waiver details to salesforce')
      p docusign_api.list_envelopes
      # signed_emails = docusign_api.recently_signed_emails
      # salesforce_api.sign_participants_waivers_by_email(signed_emails)
    end

    def assign_peer_groups_to_program(program_id, cohort_size = 10)
      logger.info('Started assigning peer groups for program')
      salesforce_api.assign_peer_groups_to_program(program_id, cohort_size)
    end

    private

    attr_reader :zoom_api, :salesforce_api, :docusign_api

    def logger
      RowanBot.logger
    end
  end
end
