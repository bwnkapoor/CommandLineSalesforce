require_relative 'salesforce'
require_relative 'apexbase'
require 'nokogiri'

class ApexPage
  include ApexBase
  attr_reader :body, :name, :folder, :id, :local_name

  def file_ext
    return '.page'
  end

  def controller
    if !@body
      pull
    end
    doc = Nokogiri::HTML @body
    apex_page = doc.css "page"
    if apex_page && !apex_page.empty?
      apex_page = apex_page[0]
      ctrl_attr = apex_page.attributes["controller"]
      if ctrl_attr
        ctrl_attr.value
      end
    end
  end

  def extensions
    if !@body
      pull
    end
    doc = Nokogiri::HTML @body
    apex_page = doc.css "page"
    if apex_page && !apex_page.empty?
      apex_page = apex_page[0]
      ctrl_attr = apex_page.attributes["extensions"]
      if ctrl_attr
        ctrl_attr.value.split ","
      end
    end
  end

  def initialize(options={})
    @body = options[:Markup]
    @name = options[:Name]
    @folder = 'pages'
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
    cls_member_id = Salesforce.instance.restforce.create( "ApexPageMember", Body: body,
                                                             MetadataContainerId: metadataContainer.id,
                                                             ContentEntityId: id
                                            )
    puts cls_member_id
  end
end