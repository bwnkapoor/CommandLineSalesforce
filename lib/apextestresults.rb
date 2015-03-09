class ApexTestResults
  attr_reader :successes, :failures, :total_time, :others

  def initialize( results )
    @others = []
    if results.class == Faraday::Response
      if results.body.class == Hash
        total_time = results.body["totalTime"]
        initialize_failures results
        initialize_successes results
      else
        parse_asynch results
      end
    else
      @successes = results["successes"]
      @failures = results["failures"]
      @total_time = results["totalTime"]
    end
  end

  def failures?
    failures && failures.length > 0
  end

  def num_tests_ran
    successes.length + failures.length + others.length
  end

  def to_hash
    hash = {}
    self.instance_variables.each {|var| hash[var.to_s.delete("@")] = self.instance_variable_get(var) }
    hash
  end

  private
    def initialize_failures sync_results
      @failures = []
      sync_results.body["failures"].each do |failure|
        res = {
          'methodName'=>failure["methodName"],
          'seeAllData'=>failure["seeAllData"],
          'time'=>failure["time"],
          'stackTrace'=>failure["stackTrace"],
          'message'=>failure["message"]
        }
        @failures.push res
      end
    end

    def initialize_successes sync_results
      @successes = []
      sync_results.body["successes"].each { |success|
        res = {
                'methodName'=>success["methodName"],
                'seeAllData'=>success["seeAllData"],
                'time'=>success["time"]
        }
        @successes.push res
      }
    end

    def parse_asynch async_results
      @successes = []
      @failures = []

      async_results.body.each do |test_res|
        method_name = test_res["MethodName"],
        outcome = test_res["Outcome"]

        if outcome == "Fail"
          @failures.push({
            "methodName"=>method_name,
            "message"=>test_res["Message"],
            "stackTrace"=>test_res["StackTrace"],
            "logid"=>test_res["ApexLogId"]
          })
        elsif outcome == "Pass"
          @successes.push({
            "methodName"=>method_name,
            "logid"=>test_res["ApexLogId"]
          })
        else
          @others.push({
            "data"=>test_res
          })
        end
      end
    end
end