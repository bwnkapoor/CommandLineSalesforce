require_relative 'salesforce'

class SalesforceJob
  attr_reader :id

  def initialize( options={} )
    @id = options["Id"]
  end

  def monitor
    id = @id
    Salesforce.instance.metadata_query( "Select ApexClassId,Status,ExtendedStatus,ParentJobId from ApexTestQueueItem where ParentJobId = '#{id}'" )
  end

  def self.run_tests_asynchronously class_ids
    res = Salesforce.instance.run_tests_asynchronously class_ids
    if res.response.class == Net::HTTPOK
      SalesforceJob.new( {"Id"=>res.parsed_response} )
    end
  end
end