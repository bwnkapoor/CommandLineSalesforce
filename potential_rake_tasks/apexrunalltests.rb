# Needs some work.
# The goal is to run the tests
# then write them to a YAML file
#  The issue:
#    the format should have an array wrapped around the results
#    results are be written in YAML immediatly in order to ensure we do not loose data
def run_tests_in_name_space
  store_environment_login
  classes = Salesforce.instance.query("Select Id, Name from ApexClass where NamespacePrefix=null").current_page
  classes = classes.map(&:Name)
  puts "Running #{classes.length} tests syncronously...\nBe Patient it might take some time"
  #classes = classes.join(",")
  totalResults = []
  classes.each do |cls|
    syncTestUrl = "/services/data/v33.0/tooling/runTestsSynchronous/?classnames=#{cls}"
    begin
      results = Salesforce.instance.restforce.get syncTestUrl
    rescue Exception=>e
      puts "Failed to run Test: #{cls}"
      next
    end
    puts "As promised, I didn't freeze"
    successes = []
    results.body["successes"].each do |success|
      res = {'methodName'=>success["methodName"],
              'seeAllData'=>success["seeAllData"],
              'time'=>success["time"]
      }
      successes.push(res)
    end
    failures = []
    results.body["failures"].each do |failure|
      res = {
        'methodName'=>failure["methodName"],
        'seeAllData'=>failure["seeAllData"],
        'time'=>failure["time"],
        'trace'=>failure["stackTrace"],
        'message'=>failure["message"]
      }
      failures.push res
    end
    results.body["totalTime"]
    results.body["numTestsRun"]
    results.body["numFailures"]
    
    testResults = {
      "successes"=>successes,
      "failures"=>failures,
      "totalTime"=>results.body["totalTime"],
      "numTestsRun"=>results.body["numTestsRun"],
      "numFailures"=>results.body["numFailures"],
      "class"=>cls
    }
    File.open('Test_Results.yml', 'a') {|f| f.write testResults.to_yaml }
    puts "just ran #{cls}"
  end

  #File.open('Test_Results.yml', 'a') {|f| f.write totalResults.to_yaml }
  puts "Please checkout Test_Results.yml"
end