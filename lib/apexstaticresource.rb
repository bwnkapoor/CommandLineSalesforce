require_relative 'salesforce'
require_relative 'apexbase'
require 'mime/types'

class StaticResource
  include ApexBase
  attr_reader :body, :name, :folder, :content_type

  def file_ext
    ext = MIME::Types[@content_type]
    if ext.first
      ext = ext.first.extensions.first
    else
      ext = "resource"
    end
    return ".#{ext}"
  end

  def content_type
    if !@content_type
      @content_type = MIME::Types.of(@full_name).first.content_type
    end
    @content_type
  end

  def initialize(options={})
    @body = options[:Body]
    @id = options[:Id]
    @full_name = options[:FullName]
    @test_results = options[:TestResults]
    @content_type = options[:ContentType]
    @folder = 'staticresources'
    @name = options[:Name]
  end

  def id
    if !@id
      definition = get_class_sf_instance.current_page
      if !definition.empty?
        @id = definition[0].Id
      end
    end

    @id
  end

  def path
    folder.to_s + "/" + name.to_s + file_ext.to_s
  end

  def pull
    file_request = get_class_sf_instance
    cls = file_request.current_page[0]
    if cls
      @content_type = cls.ContentType
      @body = Salesforce.instance.sf_get_callout( cls.Body ).body
      @id = cls.Id
    else
      raise "StaticResource DNE #{self.name}"
    end
  end

  def self.all
    Salesforce.instance.query("Select Name from StaticResource")
  end

  def save( metadataContainer )
    if id
      cls_member_id = Salesforce.instance.restforce.update( "StaticResource",
                                                               Body: Base64.encode64(body),
                                                               Name: name,
                                                               Id: id

                      )

   else
      cls_member_id = Salesforce.instance.restforce.create( "StaticResource" ,
                                                            Name: name,
                                                            Body: Base64.encode64(body).force_encoding("utf-8"),
                                                            ContentType: content_type
                       )
   end
   cls_member_id
  end

  def get_class_sf_instance( searching_name=@name )
    Salesforce.instance.metadata_query("Select+Id,Name,Body,ContentType+from+StaticResource+where+name=\'#{searching_name}\'")
  end
end
