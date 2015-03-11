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