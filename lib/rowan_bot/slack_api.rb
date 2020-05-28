require 'slack-ruby-client'

module RowanBot
  class SlackAPI
    def initialize(token)
      Slack.configure do |config|
        config.token = token
        raise 'Missing slack token!' unless config.token
      end
      @client = Slack::Web::Client.new
    end

    def create_peer_group_channels(names)
      names.map do |name|
        channel = client.conversations_create(name: name, is_private: true).channel
        logger.info("Created channel #{name}")
        { 'name' => channel.name, 'id' => channel.id }
      end
    end

    def add_users_to_peer_group_channel(channel_id, user_ids)
      logger.info("Adding users to #{channel_id}")
      client.conversations_invite(channel: channel_id, users: user_ids.join(','))
    end

    def add_slack_ids_to_users(users)
      slack_users = client.users_list.members
      users.map do |user|
        slack_user = slack_users.find { |slack_u| slack_u.profile.email.eql?(user['email']) }
        raise "Slack user #{user['email']} is not in this workspace" if slack_user.nil?
        
        logger.info("Found user #{user['email']}")
        user['slack_id'] = slack_user.id
        user
      end
    end

    private

    attr_reader :client

    def logger
      RowanBot.logger
    end
  end
end
