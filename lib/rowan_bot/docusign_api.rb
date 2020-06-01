require 'docusign_esign'

module RowanBot
  class DocuSignAPI 

    @@TOKEN_REPLACEMENT_IN_SECONDS = 10 * 60 # 10 minutes 
    @@TOKEN_EXPIRATION_IN_SECONDS = 60 * 60 # 1 hour 

    def initialize
      @configuration = DocuSign_eSign::Configuration.new
      @api_client = DocuSign_eSign::ApiClient.new(@configuration)
      # Use account.docusign.com for production and account-d.docusign.com for sandbox
      @aud = ENV['BZ_DOCUSIGN_HOST']
      @client_id = ENV['BZ_DOCUSIGN_API_KEY']
      @rsa_pk = ENV['BZ_DOCUSIGN_RSA_PRIVATE_KEY']
      # The sender's email can't be used here.
      # This is the guid for the impersonated user (the sender).
      @impersonated_user_guid = ENV['BZ_DOCUSIGN_USER_GUID']

      # If a target account is not specified then the user's default
      # account will be used
      @target_account_id = "FALSE"
      @expireIn = 0
    end

    def list_envelopes
      print("\nListing the account's envelopes...")
      check_token
      envelope_api = DocuSign_eSign::EnvelopesApi.new(@api_client)
      options =  DocuSign_eSign::ListStatusChangesOptions.new
      options.from_date = (Date.today - 30).strftime("%Y/%m/%d")
      envelopes_list = envelope_api.list_status_changes(@account_id, options)

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

    def check_token
      @now = Time.now.to_f # seconds since epoch
      # Check that the token should be good
      if @token == nil or ((@now + @@TOKEN_REPLACEMENT_IN_SECONDS) > @expireIn)
        if @token == nil
          puts "\nStarting up: fetching token"
        else
          puts "\nToken is about to expire: fetching token"
        end
        update_token
      end
    end

    def update_token
      @api_client.set_oauth_base_path(@aud)
      token = @api_client.request_jwt_user_token(@client_id, @impersonated_user_guid, @rsa_pk)
      @account = get_account_info(token.access_token)
      # puts @@account.to_yaml
  
      @api_client.config.host = @account.base_uri
      @account_id = @account.account_id
      @token = token.access_token
      @expireIn = Time.now.to_f + @@TOKEN_EXPIRATION_IN_SECONDS # would be better to receive the expires
      # info from DocuSign but it is not yet returned by the SDK.
      puts "Received token"
    end
  
    def get_account_info(access_token)
      response = @api_client.get_user_info(access_token)
      accounts = response.accounts
      target = @target_account_id
  
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

end # end RowanBot module
