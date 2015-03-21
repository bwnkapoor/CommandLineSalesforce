require_relative 'salesforce'
require_relative 'apexbase'
require 'yaml'

class ValidationRule
  include ApexBase
  attr_reader :metadata, :id
  attr_accessor :fullname

  def initialize( options={} )
    @metadata = options["Metadata"]
    @fullname = options["FullName"]
    @name = options["Name"]
    @id = options["Id"]
  end

  def self.get_class_sf_instance( name )
    Salesforce.instance.metadata_query( "Select Id, Metadata, FullName, NamespacePrefix, TableEnumOrId from ValidationRule limit 1" )
  end

  def save
    Salesforce.instance.metadata_update( self.class.to_s, @id, { body: {"FullName": @fullname, "Metadata": @metadata}.to_json } )
  end
end