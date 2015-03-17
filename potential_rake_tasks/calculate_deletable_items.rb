# Given a ./package.xml,
# Determines which classes in ./package.xml
# Writes the calculated package to ./destruction.xml
task :lazy do
  store_environment_login
  to_delete_classes = find_members_of_type_in_package "ApexClass"
  to_delete_pages = find_members_of_type_in_package "ApexPage"
  dependencies = YAML.load_file("./dependencies.yaml")
  to_delete_pages.each do |to_del_pg|
      dependencies["pages"].delete to_del_pg
  end
  cannot_delete = find_elements_cannot_delete to_delete_classes, dependencies
  rel_test_classes = classes_test_classes
  more_cannot = []
  cannot_delete.each do |cls|
    if rel_test_classes[cls]
      more_cannot.concat rel_test_classes[cls]
    end
  end
  cannot_delete.concat more_cannot
  cannot_delete_members = to_delete_classes - cannot_delete
  other_dependencies = find_elements_cannot_delete cannot_delete_members, dependencies
  cannot_delete_members = cannot_delete_members - other_dependencies
  File.open('destruction.xml', 'w'){ |f| f.write "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
                                                 "<Package xmlns=\"http://soap.sforce.com/2006/04/metadata\">\n" +
                                                 "    <fullName>codepkg</fullName>\n" +
                                                 "    <types>\n" +
                                                 "        <members>" +
                                                 cannot_delete_members.join("</members>\n        <members>") +
                                                 "</members>\n" +
                                                 "        <name>ApexClass</name>\n" +
                                                 "    </types>\n" +
                                                 "    <types>\n" +
                                                 "        <members>" +
                                                 to_delete_pages.join("</members>\n        <members>") +
                                                 "</members>\n" +
                                                 "        <name>ApexPage</name>\n" +
                                                 "    </types>\n" +
                                                 "    <version>33.0</version>\n" +
                                                 "</Package>"
                                    }

end

task :log_dependencies do
  User::login
  pages = ApexPage.dependencies Salesforce.instance.query("Select Name from ApexPage where NamespacePrefix=null").map(&:Name)
  components = ApexComponent.dependencies Salesforce.instance.query("Select Name from ApexComponent where NamespacePrefix=null").map(&:Name)
  classes = ApexClass.dependencies Salesforce.instance.query("Select Name from ApexClass where NamespacePrefix=null").map(&:Name)
  dependencies = {"components"=>components, "pages"=>pages, "classes"=>classes[:dependencies]}
  File.open('dependencies.yaml', 'w') {|f| f.write dependencies.to_yaml }
  File.open('not_defined.yaml', 'w') {|f| f.write classes[:symbol_tables_not_defined].to_yaml }
end

def find_classes_unaccounted_for
  User::login
  all_apex_classes = []
  Salesforce.instance.query( "Select Name from ApexClass where NamespacePrefix=null").each { |pg|
    all_apex_classes.push( pg )
  }
  all_apex_classes = all_apex_classes.map(&:Name)
  all_apex_classes.each_index { |i| all_apex_classes[i] = all_apex_classes[i].upcase }
  classes = ApexClass.load_from_test_coverage
  accounted_for_classes = classes.map(&:name)
  accounted_for_classes.each_index { |i| accounted_for_classes[i] = accounted_for_classes[i].upcase }
  missing_classes = all_apex_classes.select{ |class_name|
    !accounted_for_classes.include?(class_name)
  }
  missing_classes
end

def find_elements_cannot_delete attempt_to_delete, dependencies
  all_classes = dependencies["classes"]
  all__markup = dependencies["pages"]
  all__markup.merge! dependencies["components"]

  list_to_delete = attempt_to_delete
  puts "Size: #{list_to_delete.length}"
  #list_to_delete = list_to_delete - known_cannot_delete
  #puts "Size: #{list_to_delete.length}"
  cannot_delete = []
  all_classes.each_key do |org_class|
    classes_to_stay_due_to_dependencies = all_classes[org_class] & list_to_delete
    if( ( classes_to_stay_due_to_dependencies ).length > 0 && !list_to_delete.include?(org_class) )
      cannot_delete.concat classes_to_stay_due_to_dependencies
    end
  end

  all__markup.each_key do |org_pages|
    classes_to_stay_due_to_dependencies = all__markup[org_pages] & list_to_delete
    if( ( classes_to_stay_due_to_dependencies ).length > 0 )#&& !list_to_delete.include?(org_class) )
      cannot_delete.concat classes_to_stay_due_to_dependencies
    end
  end

  cannot_delete.uniq!
  if( !cannot_delete.empty? )
    puts "how many times?" + cannot_delete.length.to_s
    cannot_delete.concat find_elements_cannot_delete (attempt_to_delete-cannot_delete), dependencies
  end

  cannot_delete
end

task :compile_all do
  User::login

  classes = Salesforce.instance.query( "Select Id,Name,Body from ApexClass where NamespacePrefix=null")
  chunking_size = 20
  classes.each_slice( chunking_size ).to_a.each_with_index do |chunk, i|
    container = MetadataContainer.new( DateTime.now.to_time.to_i.to_s )
    puts "saving the container"
    container.save()

    chunk.each_with_index do |cls, i|
      puts "Saving... #{cls.Name}"
      cls = ApexClass.new( cls )
      cls.save container
    end

    asynch = ContainerAsyncRequest.new( container.id )
    deploy_id = asynch.save
    results = nil
    while !results || (results.State != 'Completed' && results.State != 'Failed')
      puts "sleeping"
      sleep(1)
      results = Salesforce.instance.metadata_query "Select DeployDetails, State from ContainerAsyncRequest where id = \'#{deploy_id}\'"
      results = results.body.current_page[0]
    end

    has_errors = false
    results.DeployDetails.allComponentMessages.each do |message|
      fileName = message.fileName.to_s
      if message.success then puts "Success" else puts "Oh No!" end
      if !message.success
        has_errors = true
        puts message.problem.to_s
        puts message.lineNumber.to_s
        puts message.problemType.to_s
        #puts saving_classes[fileName].local_name
      end
    end

    if !has_errors
      puts "Saved"
    else
      puts "Failed to save #{container.id}"
    end

    puts "Compiled #{i+1}/#{chunking_size}"
  end
end

def classes_test_classes
  classToTestClasses = {}
  dependencies = YAML.load_file( "./dependencies.yaml" )
  Salesforce.instance.query( "Select Name from ApexClass where Namespaceprefix=null").each do |cls|
    cls = ApexClass.new( cls )
    if cls.test_class?
      if dependencies["classes"][cls.name]
        dependencies["classes"][cls.name].each do |key|
          test_owner = classToTestClasses[key]
          if test_owner
            test_owner.push( cls.name )
          else
            classToTestClasses[key] = [cls.name]
          end
        end
      else
        puts "Not in the dependencies list: #{cls.name}"
      end
    end
    puts "#{cls.name} is test? #{cls.test_class?}"
  end
  classToTestClasses
end