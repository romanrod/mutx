module Mutx
  module API
    module Results

      # @param [Hash] options = {:msg}
      def self.show(options = {})

        response = self.structure
        response["results"] = Mutx::Results.all_results.map{|result| Mutx::API::Result.info(result["_id"])}
        response["message"] = "No results found" if (response["size"] = response["results"].size).zero?
        response

      end

      def self.find_by_key keyword
        response = self.structure
        response["results"] = Mutx::Results.find_for(keyword).map{|result| Mutx::API::Result.info(result["_id"])}
        response["message"] = "No results found" if (response["size"] = response["results"].size).zero?
        response
      end

      def self.structure
        response = {
          "project_name" => Dir.pwd.split("/").last,
          "results" => []
        }
        response
      end
    end
  end
end
