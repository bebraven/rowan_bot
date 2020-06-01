require 'docusign_esign'

module RowanBot
  class DocuSignAPI 

    def initialize
      @configuration = DocuSign_eSign::Configuration.new
      @api_client = DocuSign_eSign::ApiClient.new(@configuration)
    end

    def list_envelopes
      print("\nListing the account's envelopes...")
      envelopes_list = ListEnvelopes.new(@api_client).list
      envelopes = envelopes_list.envelopes
      if envelopes_list != nil and envelopes.length > 2
        print("\nResults for %d envelopes were returned. Showing the first two:" % [envelopes_list.envelopes.length])
        envelopes_list.envelopes = [envelopes[0], envelopes[1]]
      end

      envelopes_list.envelopes = [envelopes[0], envelopes[1]]
      print "\nResults: \n"
      puts envelopes_list.to_json
      print("\nDone.\n")

    rescue DocuSign_eSign::ApiError => err
      print err.to_json
      print "DocuSign SDK Error!\n   code: #{err.code}\n   message: #{err.response_body}\n\n"
    end
  end

## TODO: figure out where to put all this. Just hacking...

  class DSConfig
 
    # client_id is the same as Integrator Key
    @client_id = ENV['BZ_DOCUSIGN_API_KEY']
    # The sender's email can't be used here.
    # This is the guid for the impersonated user (the sender).
    @impersonated_user_guid = ENV['BZ_DOCUSIGN_USER_GUID']
    @signer_email = ENV['BZ_DOCUSIGN_USER_EMAIL']
    @signer_name = ENV['BZ_DOCUSIGN_USER_FULLNAME']
    @cc_email = "todo@bebraven,org"
    @cc_name = "TODO Name"
   
    # Use account.docusign.com for production
    @aud = ENV['BZ_DOCUSIGN_HOST']
    # If a target account is not specified then the user's default
    # account will be used
    @target_account_id = "FALSE"
    
    class << self
      attr_accessor :target_account_id
      attr_accessor :aud
      attr_accessor :client_id
      attr_accessor :impersonated_user_guid
      attr_accessor :signer_email
      attr_accessor :signer_name
      attr_accessor :cc_email
      attr_accessor :cc_name
  
    end
  end

  class ExampleBase
    @@TOKEN_REPLACEMENT_IN_SECONDS = 10 * 60 # 10 minutes 
    @@TOKEN_EXPIRATION_IN_SECONDS = 60 * 60 # 1 hour 
  
    @@account = nil
    @@account_id = nil
    @@token = nil
    @@expireIn = 0
    @@private_key = nil
  
    class << self
      attr_accessor :account
      attr_accessor :account_id
      attr_accessor :token
      attr_accessor :expireIn
    end
  
    def initialize(client)
      @@api_client = client
    end
  
    def check_token
      @now = Time.now.to_f # seconds since epoch
      # Check that the token should be good
      if @@token == nil or ((@now + @@TOKEN_REPLACEMENT_IN_SECONDS) > @@expireIn)
        if @@token == nil
          puts "\nStarting up: fetching token"
        else
          puts "\nToken is about to expire: fetching token"
        end
        self.update_token
      end
    end
  
    def update_token
      rsa_pk = ENV['BZ_DOCUSIGN_RSA_PRIVATE_KEY']
      @@api_client.set_oauth_base_path(DSConfig.aud)
      token = @@api_client.request_jwt_user_token(DSConfig.client_id, DSConfig.impersonated_user_guid, rsa_pk)
      @@account = get_account_info(token.access_token)
      # puts @@account.to_yaml
  
      @@api_client.config.host = @@account.base_uri
      @@account_id = @@account.account_id
      @@token = token.access_token
      @@expireIn = Time.now.to_f + @@TOKEN_EXPIRATION_IN_SECONDS # would be better to receive the expires
      # info from DocuSign but it is not yet returned by the SDK.
      puts "Received token"
    end
  
    def get_account_info(access_token)
      # code here
      response = @@api_client.get_user_info(access_token)
      accounts = response.accounts
      target = DSConfig.target_account_id
  
      if target != nil and target != "FALSE"
        accounts.each do |acct|
          if acct.account_id == target
            return acct
          end
        end
        raise "The user does not have access to account #{target}"
      end
  
      accounts.each do |acct|
        if acct.is_default
          return acct
        end
      end
    end
  end

  # Lists all envelopes in the account within the last month.
  class ListEnvelopes < ExampleBase
    def list
      check_token
      envelope_api = DocuSign_eSign::EnvelopesApi.new(@@api_client)
      options =  DocuSign_eSign::ListStatusChangesOptions.new
      options.from_date = (Date.today - 30).strftime("%Y/%m/%d")
      envelope_api.list_status_changes(@@account_id, options)
    end
  end

end # end RowanBot module
