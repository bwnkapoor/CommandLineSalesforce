require_relative 'salesforce'
require 'io/console'
require_relative 'apexbase'
require 'base64'
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
    if @body && !@actual_body
      @actual_body = Salesforce.instance.sf_get_callout @body
    end
    @actual_body
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
    @actual_body = options[:ActualBody]
    @folder = 'staticresources'
    @name = options[:Name]
  end

  def self.all
    Salesforce.instance.query("Select Name from StaticResource")
  end

  def save( metadataContainer )
    if id
      cls_member_id = Salesforce.instance.restforce.update( "StaticResource",
                                                               Body: Base64.encode64(body).force_encoding("utf-8"),
                                                               Name: name,
                                                               Id: id

                      )

   else
      cls_member_id = Salesforce.instance.create( "StaticResource" , {
                                                        body: {
                                                            Name: name,
                                                            Body: Base64.encode64(body).force_encoding("utf-8"),
                                                            ContentType: content_type
                                                        }.to_json
                                                  }
                       )
   end
   cls_member_id
  end

  def self.get_class_sf_instance( searching_name=@name )
    Salesforce.instance.metadata_query("Select+Id,Name,Body,ContentType+from+StaticResource+where+name=\'#{searching_name}\'")
  end

  def self.create_from_template template, name
    puts "The actual extension type"
    extension_type = $stdin.gets.chomp
    self.new( {
                 Name: name,
                 ActualBody: template.read,
                 FullName: name + "." + extension_type
            } )
  end

end
