task :delete, [:file_name] do |t, args|
  store_environment_login
  #records_to_delete = Array.new
  #records_to_delete.push( Hash[{"id"=>"01p17000000DNfyAAG"}] )
  x = Salesforce.instance.restforce.destroy( "ApexClass", "01pG0000004sytgIAA" )
=begin
  records_to_delete = []
  to_delete = {"Id"=>"01pj0000003DYg4AAG"}
  records_to_delete.push( to_delete )
  x = Salesforce.instance.bulk.delete( "ApexClass", records_to_delete, true )
=end
  byebug
  puts "Hello"
end