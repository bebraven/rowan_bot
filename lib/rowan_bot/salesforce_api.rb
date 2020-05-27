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

    def assign_peer_groups_to_program(program_id, cohort_size)
      program = client.find('Program__c', program_id)
      logger.info("Found program #{program.Name}")
      cohorts = client.query(
        "select Id, Letter__c from CohortSchedule__c where Program__c = '#{program.Id}'"
      )
      cohorts.inject([]) do |acc, cohort|
        acc + assign_peer_groups_to_cohort(program, cohort, cohort_size)
      end
    end

    private

    attr_reader :client

    def assign_peer_groups_to_cohort(program, cohort, cohort_size)
      logger.info('Getting participants for cohort schedule')
      participants = client.query("select Id, Name from Participant__c where Cohort_Schedule__c = '#{cohort.Id}'")
      # There must be at least cohort_size people to get this to create
      # peer groups
      peer_group_count = (participants.count / cohort_size.to_f).floor
      peer_groups = create_peer_groups(program, cohort, peer_group_count)
      assign_participants_to_peer_groups(participants, peer_groups, peer_group_count)
    end

    def create_peer_groups(program, cohort, count)
      1.upto(count) do |group|
        name = "Booster Session #{program.Session__c} Cohort #{cohort.Letter__c} Group #{group}"
        client.upsert(
          'Cohort__c',
          'Name',
          'Name': name,
          'Program__c': program.Id,
          'Cohort_Schedule__c': cohort.Id,
          'Peer_Group_ID__c': group
        )
        logger.info("Upsert peer group: #{name}")
      end
      client.query("select Id, Name from Cohort__c where Cohort_Schedule__c = '#{cohort.Id}'")
    end

    def assign_participants_to_peer_groups(participants, peer_groups, cohort_quantity)
      participants.each_with_index.map do |participant, idx|
        peer_group = peer_groups.to_a[idx % cohort_quantity]
        client.update('Participant__c', Id: participant.Id, Cohort__c: peer_group.Id)
        logger.info("#{participant.Name} assigned to #{peer_group.Name}")
        { name: participant.Name, peer_group: peer_group.Name }
      end
    end

    def logger
      RowanBot.logger
    end
  end
end
