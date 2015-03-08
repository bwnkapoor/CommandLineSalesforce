class ApexTestResults
  attr_reader :successes, :failures, :total_time

  def initialize( sync_results )
    if( sync_results.class == Faraday::Response )
      total_time = sync_results.body["totalTime"]
      initialize_failures sync_results
      initialize_successes sync_results
    else
      @successes = sync_results["successes"]
      @failures = sync_results["failures"]
      @total_time = sync_results["totalTime"]
    end
  end

  def num_tests_ran
    successes.length + failures.length
  end

  private
    def initialize_failures sync_results
      @failures = []
      sync_results.body["failures"].each do |failure|
        res = {
          'methodName'=>failure["methodName"],
          'seeAllData'=>failure["seeAllData"],
          'time'=>failure["time"],
          'trace'=>failure["stackTrace"],
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
end