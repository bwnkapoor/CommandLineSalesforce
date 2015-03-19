require_relative 'salesforce'
require_relative 'apexbase'
require 'mime/types'

class StaticResource
  include ApexBase
  attr_reader :content_type

  def file_ext
    ".resource"
  end

  def symbolic_ext
    ext = MIME::Types[@content_type]
    if ext.first
      ext = ext.first.extensions.first
    else
      ext = ".resource"
    end
    return ".#{ext}"
  end

  def body
    if @body
      Salesforce.instance.sf_get_callout @body
    end
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

  def self.get_class_sf_instance( searching_name=@name )
    Salesforce.instance.metadata_query("Select+Id,Name,Body,ContentType+from+StaticResource+where+name=\'#{searching_name}\'")
  end
end
