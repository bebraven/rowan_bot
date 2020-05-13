module RowanBot
  # Tasks class for tasks to be done
  class Tasks
    def initialize(zoom_api)
      unless zoom_api.class.eql?(ZoomAPI)
        raise ArgumentError(
          'Not instance of zoom api'
        )
      end

      @zoom_api = zoom_api
    end

    def add_participants_to_meetings(meeting_id, participants)
      participants.each do |participant|
        zoom_api.add_registrant(meeting_id, participant)
      end
    end

    def create_weekly_zoom_meeting(user_id, meeting_details)
      zoom_api.create_meeting(user_id, meeting_details)
    end

    def test
      'Hello World'
    end

    private

    attr_reader :zoom_api
  end
end
