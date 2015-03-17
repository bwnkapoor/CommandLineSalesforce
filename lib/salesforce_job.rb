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
    else
      raise res
    end
  end

  def monitor_until_done
    escape_status = ["Aborted", "Completed", "Failed"]
    puts "Monitoring Job: #{id}"
    status = nil
    while !escape_status.include?status
      sleep(5)
      monitoring_status = monitor.current_page[0]
      status = monitoring_status.Status
      puts "Status: #{status}"
    end
    puts "Keep this !#{monitoring_status.ParentJobId}'"
    results = Salesforce.instance.metadata_query( "Select MethodName,Outcome,StackTrace,TestTimestamp,Message,ApexLogId from ApexTestResult where AsyncApexJobId='#{monitoring_status.ParentJobId}'" )
    ApexTestResults.new results
  end
end