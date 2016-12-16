# encoding: utf-8
module Mutx
  module API
    class Result
      def self.get_for_task(task_id)
        task = Mutx::Tasks::Task.get(task_id)
        if task
          {
            "project_name" => Dir.pwd.split("/").last,
            "task" => {id:task.id, name:task.name},
            "results" => results_list_for(task.id)
          }
        else
          {"results" => results_list}
        end
      end

      def self.results_list_for(task_id)
        task_results = Mutx::Results.results_ids_for(task_id)
        task_results.map do |result_id|
          info(result_id)
        end
      end

      def self.info(result_id)
        result = Mutx::Results::Result.get(result_id)
        if result
          result.api_response
        else
          {"message" => "Result #{result_id} not found"}
        end
      end

      # query_string is like "first.object.in.a.json"
      def self.data result_id, query_string=nil
        result = self.info result_id
        if query_string
          {"execution_data" =>Mutx::API::Path.data(result["execution_data"], query_string)}
        else
          {"type" => "result", "_id" => result["_id"], "status" => result["status"], "execution_data" => result["execution_data"]}
        end
      end

      def self.status result_id
        result = self.info result_id
        {"type" => "result", "status" => result["status"]}
      end

      def self.output result_id
        result = Mutx::Results::Result.get(result_id)
        if result
          result.console_output
        else
          "No content to display"
        end
      end

      def self.last_notified quantity
        results = []
        result = Mutx::Database::MongoConnector.last_notified quantity
        if result
          result.each do |line|
            new_line = "[***********]\n".concat line["task"]["name"].upcase.concat " => ".concat (Time.at(line["started_at"])).to_s.concat "[***********]\n"
            new_line.slice! "-0300"
            results << new_line
            new_line = nil
          end
          results
          res = results.join(",").gsub(/[,]/, "\n\n")
          res
        else
          "No response to display"
        end
      end

    end
  end
end