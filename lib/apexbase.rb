require 'yaml'

module ApexBase
  SYMBOLIC_FILE_NAME = 'symbolic_table.yaml'
  BASE_DIR = "/home/justin/work"

  attr_reader :name

  def load_from_local_file file_path
    file = File.open( file_path, 'r' )
    @body = file.read
    @full_name = file_path
    fName = File.basename file
    @local_name = file_path
    base_file_name = File.basename file, File.extname(file)
    @name = base_file_name
  end

  def folder
    instance_dir = User.session_user.local_root_directory
    BASE_DIR + "/#{instance_dir}/#{@folder}"
  end

  def body
    if !@body
      pull
    end
    @body
  end

  def path
    folder.to_s + "/" + name.to_s + file_ext.to_s
  end

  def delete
    url = "/services/data/v33.0/sobjects/#{self.class}/#{id}"
    res = Salesforce.instance.sf_delete_callout( url )
    puts res.response
  end

  def id
    if !@id
      definition = self.class.get_class_sf_instance(name).current_page
      if !definition.empty?
        @id = definition[0].Id
      end
    end

    @id
  end

  def write_file
    FileUtils.mkdir_p folder
    File.open( path, 'w' ){ |f| f.write body }
  end

  def write_symbolic_links
    FileUtils.mkdir_p file.symbolic_folder
    begin
      FileUtils.ln_s "#{file.path}", "#{file.symbolic_path}"
    rescue Errno::EEXIST

    end
  end

  def loaded_symbolic
    links = load_symbol_links
    if links && links[self.class] && links[self.class][name]
      links[self.class][name]
    else
      nil
    end
  end

  def symbolic_folder
    if loaded_symbolic then loaded_symbolic["local_name"] else @folder end
  end

  def symbolic_path
    symbolic_folder.to_s + "/" + name.to_s + symbolic_ext.to_s
  end

  def symbolic_ext
    file_ext
  end

  def log_symbolic_link
    symbolic_link = load_symbol_links
    if !symbolic_link[self.class]
      symbolic_link[self.class] = {}
    end
    symbolic_link[self.class][@name] = {
      "local_name"=>File.dirname( @local_name ),
      "id"=>@id
    }
    File.open(SYMBOLIC_FILE_NAME, 'w'){ |f| f.write YAML.dump symbolic_link }
  end

  def find_symbol_local_link
    symbols = load_symbol_links
    if symbols[self.class] && symbols[self.class][@name]
      f = symbols[self.class][@name]["local_name"]
      @folder = File.dirname f
    else
      nil
    end
  end

  def load_symbol_links
    begin
      symbolic_link = YAML.load_file SYMBOLIC_FILE_NAME
    rescue Exception=>e
      symbolic_link = {}
      puts "Symbolic Table file Not found"
    end
    symbolic_link
  end

  def self.pull fileNames, type
    classes = []
    puts "Pulling #{type}"
    if fileNames.length == 1 && fileNames[0] == "*"
      fileNames = type.all.map(&:Name)
    end
    fileNames.each do |file|
      begin
        puts "Pulling #{file}"
        classes.push do_pull( type, file )
      rescue Exception=>e
        puts e.to_s
      end
    end
    classes
  end

  def self.do_pull type, name
    file_request = type.get_class_sf_instance name
    cls = file_request.current_page[0]
    if cls
      cls = type.new cls
    else
      raise "Class DNE #{self.name}"
    end

    cls
  end

  def self.apex_member_factory(file_name)
    type = File.extname( file_name )
    whole_name = file_name
    file_name = File.basename file_name, File.extname(file_name)

    if( type == ".cls" )
      ApexClass
    elsif( type == ".page" )
      ApexPage
    elsif( type == ".component" )
      ApexComponent
    elsif( type == ".trigger" )
      ApexTrigger
    elsif( type == ".resource" || File.dirname(whole_name).end_with?("staticresources") )
      StaticResource
    else
      raise "Not Supported Type #{type}"
    end
  end

  def self.create file_type
    type = self.apex_member_factory file_type
    file = File.open("/home/justin/.rake/templates/#{type}", "r")
    puts "file name:"
    name = $stdin.gets.chomp
    member = type.create_from_template file, name
    member.write_file
  end
end