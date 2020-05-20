require 'faraday'
require 'json'

module RowanBot
  # ZoomAPI class to wrap around the zoom API
  class ZoomAPI
    BASE_URL = 'https://api.zoom.us/v2'.freeze

    def initialize(token)
      @token = token
    end

    def create_meeting(user_id, data)
      url = "#{BASE_URL}/users/#{user_id}/meetings"

      post(url, data)
    end

    def add_registrant(meeting_id, data)
      url = "#{BASE_URL}/meetings/#{meeting_id}/registrants"

      post(url, data)
    end

    private

    attr_reader :token

    def fetch(url, params = {})
      response = Faraday.get(url, params, shared_headers)

      extract_response(response)
    end

    def post(url, data)
      response = Faraday.post(url, data.to_json, shared_headers)

      extract_response(response)
    end

    def extract_response(response)
      unless [201, 200].include?(response.status)
        raise "Something went wrong communicating with zoom: #{response.body}"
      end

      JSON.parse(response.body)
    end

    def shared_headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      }
    end
  end
end
