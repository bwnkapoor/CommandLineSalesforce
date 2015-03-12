require_relative 'salesforce'
require_relative 'apexbase'
require_relative 'apexmarkup'

class ApexPage
  include ApexBase
  include ApexMarkup
  attr_reader :name, :folder, :id, :local_name

  def file_ext
    return '.page'
  end

  def container_tag
    return "page"
  end

  def type
    "ApexPage"
  end

  def body
    if !@body
      pull
    end
    @body
  end

  def initialize(options={})
    @body = options[:Markup]
    @name = options[:Name]
    @folder = 'pages'
  end

  def dependencies
    depends = []
    depends.push controller
    depends.concat extensions
    depends
  end

  def self.dependencies page_names
    pg_name_to_dependencies = {}
    page_names.each do |pg_name|
      pg = ApexPage.new( {Name: pg_name} )
      pg_name_to_dependencies[pg_name] = pg.dependencies
    end
    pg_name_to_dependencies
  end

  def path
    folder.to_s + "/" + name.to_s + file_ext.to_s
  end

  def pull
    file_request = get_class_sf_instance()
    cls = file_request.current_page[0]
    @body = cls.Markup
    @id = cls.Id
  end

  def self.pull fileNames
    pages = []
    fileNames.each do |file|
      pg = ApexPage.new( {Name: file} )
      pg.pull
      pages.push pg
    end

    pages
  end

  def get_class_sf_instance( searching_name=name )
    Salesforce.instance.query("Select+Id,Name,Markup,SystemModstamp,NamespacePrefix+from+ApexPage+where+name=\'#{searching_name}\' and namespacePrefix=null")
  end

  def save( metadataContainer )
    if id
      cls_member_id = Salesforce.instance.restforce.create( "ApexPageMember", Body: body,
                                                               MetadataContainerId: metadataContainer.id,
                                                               ContentEntityId: id
                                              )
    else
      cls_member_id = Salesforce.instance.sf_post_callout( "/services/data/v33.0/sobjects/ApexPage" , {

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
end