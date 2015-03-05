require_relative 'salesforce'

class ContainerAsyncRequest
  attr_reader :metadata_container_id, :is_run_test

  def initialize( metadata_container_id, is_run_test=false, options={} )
    @metadata_container_id = metadata_container_id
    @is_run_test = is_run_test
  end

  def save
    Salesforce.instance.restforce.create( "ContainerAsyncRequest", MetadataContainerId: metadata_container_id)
  end
end