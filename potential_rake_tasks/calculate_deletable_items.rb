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