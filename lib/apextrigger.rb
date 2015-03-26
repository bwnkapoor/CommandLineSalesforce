require_relative 'apextestresults'
require_relative 'apexbase'
require_relative 'salesforce'

class ApexTrigger
  include ApexBase

  attr_reader :metadata

  def file_ext
    return '.trigger'
  end

  def table_enum_or_id
    matches = @body.match Regexp.new "trigger[ ]+([A-Za-z0-9_]+)[ ]+on[ ]+([A-Za-z0-9_]+)", true
    if matches
      return matches.captures[1]
    end
  end

  def initialize(options={})
    @body = options[:Body]
    @id = options[:Id]
    @test_results = options[:TestResults]
    @folder = 'triggers'
    @metadata = options[:Metadata]
    @name = options[:Name]

  end

  # Dependencies currently are not supporting extends, implements and variables of the class
  def self.get_dependencies class_name
    dependencies = []
    x = Salesforce.instance.metadata_query( "Select SymbolTable, MetaData, FullName from ApexTriggerMember where FullName = \'#{class_name}\' order by createddate desc limit 1" )
    x.body.current_page.each do |classMember|
      if classMember.SymbolTable
        classMember.SymbolTable.externalReferences.each do |xRef|
          dependencies.push xRef.name.to_s
        end
      else
        raise "No table exists! #{classMember}"
      end
    end
    puts "Dependencies for #{class_name}\n#{dependencies}"
    dependencies
  end

  def self.all
    Salesforce.instance.query("Select Name from ApexTrigger where NamespacePrefix=Null")
  end

  def self.get_class_sf_instance( searching_name=name )
    Salesforce.instance.metadata_query("Select+Id,Name,Metadata,EntityDefinitionId,Body,BodyCrc+from+ApexTrigger+where+Name=\'#{searching_name}\'")
  end

  def save( metadataContainer )
    if( id )
      puts_body = {Body: body,MetadataContainerId: metadataContainer.id,ContentEntityId: id}

      if( metadata )
        puts_body[:Metadata] = metadata
      end

      cls_member_id = Salesforce.instance.metadata_create( "ApexTriggerMember", {
                                                               body: puts_body.to_json
                                              })

    else
      cls_member_id = Salesforce.instance.sf_post_callout( "/services/data/v33.0/sobjects/ApexTrigger" , {

                                                              body: {
                                                                 "Name"=>name,
                                                                 "Body"=>body,
                                                                 "TableEnumOrId"=>table_enum_or_id
                                                              }.to_json
                                                           }
                                              )

    end
    puts cls_member_id["id"]
    cls_member_id["id"]
  end

  def self.create_from_template template, name
    content = template.read
    puts "sObject: "
    sobject = $stdin.gets.chomp
    content = content.sub("@objectName@", name)
    content = content.sub("@sObject@", sobject)
    self.new( {Body: content, Name: name} )
  end
end