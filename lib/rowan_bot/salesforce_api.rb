# frozen_string_literal: true

require 'restforce'

module RowanBot
  # SalesforceAPI class
  class SalesforceAPI
    def initialize
      @client = Restforce.new(
        username: ENV['SALESFORCE_PLATFORM_USERNAME'],
        password: ENV['SALESFORCE_PLATFORM_PASSWORD'],
        host: ENV['SALESFORCE_HOST'],
        security_token: ENV['SALESFORCE_PLATFORM_SECURITY_TOKEN'],
        client_id: ENV['SALESFORCE_PLATFORM_CONSUMER_KEY'],
        client_secret: ENV['SALESFORCE_PLATFORM_CONSUMER_SECRET'],
        api_version: ENV.fetch('SALESFORCE_API_VERSION') { '48.0' }
      )
      @participant_record_type_ids = {}
      @last_peer_groups = {}
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

    def assign_peer_groups_to_user_emails(emails)
      emails.each {|email| assign_peer_groups_to_user_email(email) }
    end

    def sign_participants_waivers_by_email(emails)
      emails.filter { |email| !set_student_waiver_field(email).nil? }
    end

    def map_emails_with_peer_group(emails)
      emails.map { |email| map_email_with_peer_group(email) }
    end

    private

    attr_reader :client

    def map_email_with_peer_group(email)
      participant = find_participant_by_email(email)
      pg = participant.Cohort__r.Name
      logger.debug("  mapping #{email} to peer_group #{pg}")
      { email: email, peer_group: pg }
    end

    def assign_peer_groups_to_user_email(email, max_cap = 10)
      participant = find_participant_by_email(email)
      peer_group_id = find_or_create_peer_group(participant.Program__r.Id, participant.Cohort_Schedule__r.Id, participant.Program__r.Session__c, participant.Cohort_Schedule__r.Letter__c, max_cap)
      client.update('Participant__c', Id: participant.Id, Cohort__c: peer_group_id)
    end

    # Only implemented for Booster students at the moment.
    # If we start doing this for folks who could have multiple Participant objects, we'll
    # have to update this to account for that.
    def set_student_waiver_field(email, value = true)
      logger.info("Setting waiver for #{email} to #{value}")
      participant = find_participant_by_email(email)
      if participant.nil?
        logger.warn("Skipping #{email} - not found in salesforce")
        return
      end
      if participant.Student_Waiver_Signed__c
        logger.info("SKipping #{email} - already marked as signed in salesforce")
        return
      end

      client.update('Participant__c', Id: participant.Id, Student_Waiver_Signed__c: value)
      email
    end

    def find_participant_by_email(email)
      record_type_id = get_participant_record_type_id('Booster_Student')
      client.query("select Id, Student_Waiver_Signed__c, Cohort__r.Name, Cohort_Schedule__r.Id, Cohort_Schedule__r.Letter__c, Program__r.Id, Program__r.Session__c from Participant__c where Contact__r.email = '#{email}' AND RecordTypeId = '#{record_type_id}' ORDER BY Id DESC limit 1").first
    end

    def assign_peer_groups_to_cohort(program, cohort, cohort_size)
      logger.info('Getting participants for cohort schedule')
      participants = client.query("select Id, Name, Contact__r.Email from Participant__c where Cohort_Schedule__c = '#{cohort.Id}'")
      # There must be at least cohort_size people to get this to create
      # peer groups
      peer_group_count = (participants.count / cohort_size.to_f).floor
      peer_groups = create_peer_groups(program, cohort, peer_group_count)
      assign_participants_to_peer_groups(participants, peer_groups, peer_group_count)
    end

    def find_or_create_peer_group(program_id, cohort_id, program_letter, cohort_letter, max_cap)
      last_peer_group = get_last_peer_group(program_id, cohort_id)
      should_create_peer_group =
        if last_peer_group.nil?
          true
        else
          participant_count = client.query("select count(Id) from Participant__c where Cohort_Schedule__c = '#{cohort_id}' AND Cohort__c = '#{last_peer_group.Id}'").first
          current_current = participant_count.expr0.to_i 
          logger.debug("  participants in Cohort__c '#{last_peer_group.Id}' has hit #{max_cap}") if current_current >= max_cap
          current_current >= max_cap
        end 

      if should_create_peer_group
        group = last_peer_group.nil? ? 1 : last_peer_group.Peer_Group_ID__c.to_i + 1
        name = "Booster Session #{program_letter} Cohort #{cohort_letter} Group #{group}"
        logger.debug("  creating new peer group '#{name}' for Program__c '#{program_id}' and Cohort_Schedule__c '#{cohort_id}'")
        client.create!(
          'Cohort__c',
          'Name': name,
          'Program__c': program_id,
          'Cohort_Schedule__c': cohort_id,
          'Peer_Group_ID__c': group
        )
        last_peer_group = get_last_peer_group(program_id, cohort_id, true)
      end
      last_peer_group.Id
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
        logger.debug("  #{participant.Contact__r.Email} assigned to #{peer_group.Name}")
        { salesforce_id: participant.Id, name: participant.Name, email: participant.Contact__r.Email, peer_group: peer_group.Name }
      end
    end

    # Gets and caches the RecordTypeId for a Participant__c object given the "developername".
    # An example developername is "Booster_Student"
    def get_participant_record_type_id(developername)
      unless @participant_record_type_ids[developername]
        rti = client.query("select id from RecordType where sObjectType='Participant__c' AND developername = '#{developername}' limit 1").first
        logger.debug("Found RecordTypeId for Participant__c with #{developername}: #{rti}")
        @participant_record_type_ids[developername] = rti.Id
      end
      @participant_record_type_ids[developername]
    end

    # Gets and caches the Cohort__c record with the highest Peer_Group_ID__c
    def get_last_peer_group(program_id, cohort_schedule_id, invalidate_cache = false) 
      pg_hash_key = "#{program_id}_#{cohort_schedule_id}"
      if @last_peer_groups[pg_hash_key].nil? || invalidate_cache
        @last_peer_groups[pg_hash_key] = client.query("select Id, Name, Peer_Group_ID__c from Cohort__c where Cohort_Schedule__c = '#{cohort_schedule_id}' AND Program__c = '#{program_id}' ORDER BY Peer_Group_ID__c DESC LIMIT 1").first
      end
      @last_peer_groups[pg_hash_key] 
    end

    def logger
      RowanBot.logger
    end
  end
end
