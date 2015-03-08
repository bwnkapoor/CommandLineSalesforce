# The commented portion compiles our files in sf then reads the files to load from package.xml
# so that we can access the ApexClasses dependencies
# The uncommented out portion reads our yaml file created
# and prints out information on dependencies
task :compile_find_dependencies, [:file_name] do |t, args|
  store_environment_login
=begin
  file_name = args[:file_name]
  puts "Reading package.xml"
  classes = find_members_of_type_in_package 'ApexClass'
  classes = ApexClass.dependencies classes
  File.open('test.yml', 'w') {|f| f.write classes.to_yaml }
=end
  data = YAML.load_file 'test.yml'
  puts data.keys.length
  name_to_dependencies = remove_non_keys( data )
  cyclical = findStrongTies(name_to_dependencies)

  puts "The following items have Cyclical Dependencies #{cyclical}"

  puts "We have cyclical: #{cyclical.length}"

  name_to_dependencies = non_cyclical( name_to_dependencies )
  to_sort = remove_non_keys( name_to_dependencies )
  our_sort = to_sort.tsort
  puts "We can remove: #{our_sort.length} items here is the order\n"
  puts our_sort.reverse

end