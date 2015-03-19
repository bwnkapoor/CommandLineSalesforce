require_relative 'salesforce'
require_relative 'apexbase'
require_relative 'apexmarkup'

class ApexComponent
  include ApexBase
  include ApexMarkup

  attr_reader :local_name

  def file_ext
    return '.component'
  end

  def container_tag
    return "component"
  end

  def attributes
    doc = Nokogiri::HTML body
    apex_attributes = doc.css "attribute"
    attrs = []
    if apex_attributes && !apex_attributes.empty?
      apex_attributes.each{ |attr| attrs.push attr["type"] }
    end
    attrs
  end

  def dependencies
    puts "Logging Dependencies for: #{@name}"
    depends = []
    depends.push controller
    depends.concat extensions
    depends.concat attributes
    depends.compact
  end

  def self.dependencies page_names
    pg_name_to_dependencies = {}
    page_names.each do |pg_name|
      pg = ApexComponent.new( {Name: pg_name} )
      pg_name_to_dependencies[pg_name] = pg.dependencies
    end
    pg_name_to_dependencies
  end

  def initialize(options={})
    @body = options[:Markup]
    @folder = 'components'
    @name = options[:Name]
    @id = options[:Id]
  end

  def self.all
    Salesforce.instance.query("Select Name from ApexComponent where NamespacePrefix=null")
  end

  def self.get_class_sf_instance( searching_name=name )
    Salesforce.instance.query("Select+Id,Name,Markup,SystemModstamp,NamespacePrefix+from+ApexComponent+where+name=\'#{searching_name}\' and NamespacePrefix=null" )
  end

  def save( metadataContainer )
    if id
      cls_member_id = Salesforce.instance.restforce.create( "ApexComponentMember", Body: body,
                                                               MetadataContainerId: metadataContainer.id,
                                                               ContentEntityId: id
                                              )
    else
      cls_member_id = Salesforce.instance.sf_post_callout( "/services/data/v33.0/sobjects/ApexComponent" , {

                                                              body: {
                                                                 "Name"=>name,
                                                                 "Markup"=>body,
                                                                 "MasterLabel"=>name
                                                              }.to_json
                                                           }
                                              )
    end
    puts cls_member_id
  end

  def self.create_from_template template, name
    content = template.read
    self.new( {Markup: content, Name: name} )
  end
end