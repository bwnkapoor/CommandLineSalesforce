require_relative 'salesforce'
require_relative 'apexbase'

class ApexComponent
  include ApexBase

  attr_reader :body, :name, :folder, :id, :local_name

  def file_ext
    return '.component'
  end

  def path
    folder.to_s + "/" + name.to_s + file_ext.to_s
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