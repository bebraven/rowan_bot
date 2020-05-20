require 'restforce'

module RowanBot
  # SalesforceAPI class
  class SalesforceAPI
    def initialize(
      username:, password:, host:, security_token:, client_id:, client_secret:
    )
      @client = Restforce.new(
        username: username,
        password: password,
        host: host,
        security_token: security_token,
        client_id: client_id,
        client_secret: client_secret,
        api_version: '41.0'
      )
    end

    private

    attr_reader :client
  end
end
