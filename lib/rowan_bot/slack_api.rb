# frozen_string_literal: true

require 'slack-ruby-client'
require 'capybara/dsl'

module RowanBot
  # SlackAPI class for slack stuff
  class SlackAPI
    include Capybara::DSL

    def initialize
      Capybara.default_driver = :selenium_chrome_headless
      Slack.configure do |config|
        config.token = ENV['SLACK_TOKEN']
      end

      @client = Slack::Web::Client.new
      @slack_user = ENV['SLACK_USER']
      @slack_password = ENV['SLACK_PASSWORD']
      @slack_url = ENV['SLACK_URL']
    end

    def create_peer_group_channels(names)
      channels = client.conversations_list.channels
      to_create = []
      existing = names.map do |name|
        schan = channels.find { |chan| chan.name.eql?(name) }
        if schan.nil?
          to_create << name
          nil
        else
          { name: schan.name, id: schan.id }
        end
      end.compact

      created = to_create.map do |name|
        channel = client.conversations_create(name: name, is_private: true).channel
        logger.info("Created channel #{name}")
        { name: channel.name, id: channel.id }
      end

      [existing + created, created]
    end

    def add_users_to_peer_group_channel(channel_id, user_ids)
      logger.info("Adding users to #{channel_id}")
      client.conversations_invite(channel: channel_id, users: user_ids.join(','))
    end

    def add_slack_ids_to_users(users)
      slack_users = client.users_list.members
      users.map do |user|
        slack_user = slack_users.find { |slack_u| slack_u.profile.email.eql?(user[:email]) }
        raise "Slack user #{user[:email]} is not in this workspace" if slack_user.nil?

        logger.info("Found user #{user[:email]}")
        user[:slack_id] = slack_user.id
        user
      end
    end

    def invite_users_to_slack(emails)
      return if emails.empty?

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
