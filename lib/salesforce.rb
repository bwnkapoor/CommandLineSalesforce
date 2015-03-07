require 'restforce'
require 'salesforce_bulk'
require 'byebug'
require 'singleton'

class Salesforce
  include Singleton
  attr_reader :restforce, :sf, :bulk

  def initialize(attributes={})
    host = ENV["SF_HOST"]
    @restforce = Restforce.tooling :client_secret=>ENV["SF_CLIENT_SECRET"],
                                   :client_id=>"3MVG9fMtCkV6eLhcHZKdKpiBaGRD.nn9APDZwScPrrS1WNk0n7FZxiid9uUSJil3fxRC_jFE1Fk_McVoXI9uu",
                                   :username=>ENV["SF_USERNAME"],
                                   :password=>ENV["SF_PASSWORD"],
                                   :api_version=>SF_API_VERSION,
                                   :host=>host

    @sf = Restforce.tooling :client_secret=>ENV["SF_CLIENT_SECRET"],
                                   :client_id=>"3MVG9fMtCkV6eLhcHZKdKpiBaGRD.nn9APDZwScPrrS1WNk0n7FZxiid9uUSJil3fxRC_jFE1Fk_McVoXI9uu",
                                   :username=>ENV["SF_USERNAME"],
                                   :password=>ENV["SF_PASSWORD"],
                                   :api_version=>SF_API_VERSION,
                                   :host=>host
    @bulk = SalesforceBulk::Api.new( ENV["SF_USERNAME"], ENV["SF_PASSWORD"], false )
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
    @restforce.get "/services/data/v#{SF_API_VERSION}/tooling/query/?q=#{str_query}"
  end

  private
    SF_API_VERSION = "33.0"
end