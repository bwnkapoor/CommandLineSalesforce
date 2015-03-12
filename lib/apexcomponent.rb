require_relative 'salesforce'
require_relative 'apexbase'
require_relative 'apexmarkup'

class ApexComponent
  include ApexBase
  include ApexMarkup

  attr_reader :body, :name, :folder, :id, :local_name

  def file_ext
    return '.component'
  end

  def container_tag
    return "component"
  end

  def type
    "ApexComponent"
  end

  def path
    folder.to_s + "/" + name.to_s + file_ext.to_s
  end

  def body
    if !@body
      pull
    end
    @body
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
    depends = []
    depends.push controller
    depends.concat extensions
    depends.concat attributes
    depends
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
  end

  def pull
    file_request = get_class_sf_instance
    cls = file_request.current_page[0]
    @body = cls.Markup
    @id = cls.Id
  end

  def self.pull fileNames
    components = []
    fileNames.each do |file|
      pg = ApexComponent.new( {Name: file} )
      pg.pull
      components.push pg
    end

    components
  end

  def get_class_sf_instance( searching_name=name )
    Salesforce.instance.query("Select+Id,Name,Markup,SystemModstamp,NamespacePrefix+from+ApexComponent+where+name=\'#{searching_name}\'" )
  end

  def save( metadataContainer )
    cls_member_id = Salesforce.instance.restforce.create( "ApexComponentMember", Body: body,
                                                             MetadataContainerId: metadataContainer.id,
                                                             ContentEntityId: id
                                            )
    puts cls_member_id
  end
end