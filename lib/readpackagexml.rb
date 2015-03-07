require 'nokogiri'

class ApexMember
  attr_reader :name, :members

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
  all_members = []
  readPackage.each do |member|
    all_members.concat( clsMember.with_extensions )
  end
  all_members
end

def readPackage
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
    all_members.push( clsMember )
  end
  all_members
end

def find_members_of_type_in_package type
  classes = []
  readPackage.each do |member|
    if member.name == type
      member.members.each do |cls_name|
        classes.push cls_name
      end
    end
  end
  classes
end