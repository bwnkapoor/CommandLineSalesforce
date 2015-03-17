require 'restforce'
require 'byebug'
require 'singleton'
require 'httparty'

class Salesforce
  include Singleton
  include HTTParty
  attr_reader :restforce, :sf, :bulk

  def initialize(attributes={})
    host = ENV["SF_HOST"]
    @restforce = Restforce.tooling :client_secret=>ENV["SF_CLIENT_SECRET"],
                                   :client_id=>ENV["SF_CLIENT_ID"],
                                   :username=>ENV["SF_USERNAME"],
                                   :password=>ENV["SF_PASSWORD"],
                                   :api_version=>SF_API_VERSION,
                                   :host=>host

    @sf = Restforce.new :client_secret=>ENV["SF_CLIENT_SECRET"],
                                   :client_id=>ENV["SF_CLIENT_ID"],
                                   :username=>ENV["SF_USERNAME"],
                                   :password=>ENV["SF_PASSWORD"],
                                   :api_version=>SF_API_VERSION,
                                   :host=>host
    self.class.base_uri restforce.instance_url
    @session_id = restforce.options[:oauth_token]
  end

  def sobject_list
    sobjects = @restforce.get("/services/data/v#{SF_API_VERSION}/sobjects").body.sobjects
    list = []
    sobjects.each do |sobject|
      list << sobject.name.to_s
    end
    list
  end

  def describe( sobject_name )
    @restforce.get( "/services/data/v#{SF_API_VERSION}/sobjects/#{sobject_name}/describe").body
  end

  def workflow_rules( sobject_name )
    metadata_query( "Select+id,name,fullname,metadata+from+WorkflowRule+where+TableEnumOrId=\'#{sobject_name}\'" ).body
  end

  def query( str_query )
    return @restforce.get( "/services/data/v#{SF_API_VERSION}/query/?q=#{str_query}" ).body
  end

  def metadata_query( str_query )
    @restforce.get( "/services/data/v#{SF_API_VERSION}/tooling/query/?q=#{str_query}" ).body
  end

  def run_tests_synchronously( classes )
    classes = if classes.class == Array then classes else [classes] end
    classes = classes.join(",")
    syncTestUrl = "/services/data/v#{SF_API_VERSION}/tooling/runTestsSynchronous/?classnames=#{classes}"
    sf_get_callout( syncTestUrl, {:timeout=>300} )
  end

  def sf_get_callout( url, options={} )
    session_id = @session_id
    options[:headers]={
      "Authorization"=>"Bearer #{session_id}",
      "Content-Type"=>"application/json"
    }
    self.class.get url, options
  end

  def sf_post_callout( url, options={} )
    session_id = @session_id
    options[:headers]={
      "Authorization"=>"Bearer #{session_id}",
      "Content-Type"=>"application/json"
    }
    self.class.post url, options
  end

  def sf_delete_callout( url, options={} )
    session_id = @session_id
    options[:headers]={
      "Authorization"=>"Bearer #{session_id}",
      "Content-Type"=>"application/json"
    }
    self.class.delete url, options
  end

  def run_tests_asynchronously( class_ids )
    classes = if classes.class == Array then classes else [class_ids] end
    classes = classes.join(",")
    Salesforce.instance.sf_get_callout "/services/data/v#{SF_API_VERSION}/tooling/runTestsAsynchronous/?classids=#{classes}"
  end

  private
    SF_API_VERSION = "33.0"
end