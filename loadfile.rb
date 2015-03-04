require 'fileutils'
#require_relative 'salesforce'
require_relative 'lib/apexclass'
require_relative 'lib/apexpage'
require_relative 'lib/apexcomponent'
require_relative 'lib/apexstaticresource'


def write files
  files.each do |sf_file|
    FileUtils.mkdir_p sf_file.folder
    f = File.new( sf_file.path, "w" )
    f.write( sf_file.body )
    f.close
  end
end

cls = ApexClass.new( { :Name=>'TestController' } )
cls.pull
pg = ApexPage.new( {:Name=>"SendEmailWithSF_Attachments"} )
pg.pull
comp = ApexComponent.new( {:Name=>"Test"} )
comp.pull
resource = ApexStaticResource.new( {:Name=>"sobject_lookup"} )
resource.pull
write [cls, pg, comp, resource]
