require 'nokogiri'

class ApexMember

  def initialize( name )
    @members = []
    @name = name.to_s.delete( ' ')
    @memberTypes = {
      "ApexClass"=>".cls",
      "ApexTrigger"=>".trigger",
      "StaticResource"=>".resource",
      "ApexComponent"=>".component",
      "ApexPage"=>".page"
    }
  end

  def add( child )
    @members.push( child )
  end

  def with_extensions
    type = @memberTypes[@name]
    with_ext = []
    @members.each do |member|
      with_ext.push( member.to_s + type.to_s )
    end
    with_ext
  end

end

def readPackageXML
  file = File.open 'package.xml'
  doc = Nokogiri::XML( file )
  types = doc.css("types")
  all_members = []
  types.each do |type|
    memberName = type.css('name')[0].children[0].text
    clsMember = ApexMember.new memberName
    type.css("members").each do |member|
      child_name = member.children[0].text
      clsMember.add( child_name )
    end
    all_members.concat( clsMember.with_extensions )
  end
  all_members
end