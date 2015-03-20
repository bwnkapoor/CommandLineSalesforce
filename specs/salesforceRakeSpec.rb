require_relative '../salesforce.rake'

describe 'salesforce.rake' do
  describe '#load_from_dependences' do
    load_from_dependencies "./helpers/helpers/dependencies.yaml"
    file_content = YAML.load_file "helpers/helpers/dependencies.yaml"
  end
end