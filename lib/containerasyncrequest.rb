require_relative 'salesforce'

class ContainerAsyncRequest
  attr_reader :metadata_container_id, :is_run_test, :id

  def initialize( metadata_container_id, is_run_test=false, options={} )
    @metadata_container_id = metadata_container_id
    @is_run_test = is_run_test
  end

  def save
    @id = Salesforce.instance.restforce.create( "ContainerAsyncRequest", MetadataContainerId: metadata_container_id)
  end

  def monitor_until_complete
    results = nil
    while !results || (results.State != 'Completed' && results.State != 'Failed' && results.State != 'Error')
      puts "sleeping"
      sleep(1)
      results = Salesforce.instance.metadata_query "Select DeployDetails, State from ContainerAsyncRequest where id = \'#{@id}\'"
      results = results.current_page[0]
    end
    @results = results
  end

  def save_results_log
    has_errors = false
    @results.DeployDetails.allComponentMessages.each do |message|
      fileName = message.fileName.to_s
      if message.success then puts "Success" else puts "Oh No!" end
      if !message.success
        has_errors = true
        puts message.problem.to_s
        puts message.lineNumber.to_s
        puts message.problemType.to_s
        puts "For class: #{message.fileName}\n\n"
      else
        puts "File saved: #{message.fileName}\n\n"
      end
    end
  end
end