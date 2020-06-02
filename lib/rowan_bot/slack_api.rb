# frozen_string_literal: true

require 'slack-ruby-client'
require 'capybara/dsl'

module RowanBot
  # SlackAPI class for slack stuff
  class SlackAPI
    include Capybara::DSL

    def initialize(token, user, password, url)
      Capybara.default_driver = :selenium_chrome_headless
      Slack.configure do |config|
        config.token = token
      end

      @client = Slack::Web::Client.new
      @slack_user = user
      @slack_password = password
      @slack_url = url
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

    def invite_users_to_slack(emails)
      login_to_slack
      emails = emails.join(', ')
      logger.info("Adding users: #{emails}")

      click_on('Add')
      click_on('add many at once')
      fill_in('bulk-invites-input', with: emails)
      click_on('Add Invitees')
      click_on('Send Invitations')
    end

    private

    attr_reader :client, :slack_user, :slack_password, :slack_url

    def login_to_slack
      logger.info('Logging into slack')
      visit slack_url
      fill_in('email', with: slack_user)
      fill_in('password', with: slack_password)
      click_on('signin_btn')
    end

    def logger
      RowanBot.logger
    end
  end
end
