class ApexTestResults
  attr_reader :successes, :failures, :total_time, :others

  def initialize( results )
    @others = []
    if results.class == Faraday::Response
      if results.body.class == Hash
        total_time = results.body["totalTime"]
        initialize_failures results
        initialize_successes results
      end
    elsif results.class == Restforce::Collection
      parse_asynch results
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
    success_len = successes ? successes.length : 0
    fail_len = failures ? failures.length : 0
    others_len = others ? others.length : 0
    success_len + fail_len + others_len
  end

  def to_hash
    hash = {}
    self.instance_variables.each {|var| hash[var.to_s.delete("@")] = self.instance_variable_get(var) }
    hash
  end

  def to_s
    str = []
    str.push "Success Rate: #{successes.length}/#{num_tests_ran}"
    failures.each do |fail|
      str.push "MethodName: #{fail['methodName']}"
      str.push "Message: #{fail['message']}"
      str.push "StackTrace: #{fail['stackTrace']}"
      log_id = fail['logid']
      if( log_id )
        str.push "LogId: #{log_id}"
      end
      str.push "------------------------------------------------------------------------------------------------------------------------------------------"
    end
    str.join("\n")
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

      async_results.each do |test_res|
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