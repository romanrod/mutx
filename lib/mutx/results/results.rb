# enconding: utf-8
module Mutx
  module Results

    def self.all_results_for task_id
      Mutx::Database::MongoConnector.results_for task_id
    end

    def self.results_ids_for task_id
      all_results_for(task_id).map do |result|
        result["_id"]
      end
    end

    def self.running_results_for_task_id task_id
      Mutx::Database::MongoConnector.running_results_for_task_id task_id
    end

    def self.all_results_ids
      Mutx::Database::MongoConnector.all_results_ids
    end

    def self.find_for key
      Mutx::Database::MongoConnector.find_results_for_key key
    end

    def self.find_for_status status
      Mutx::Database::MongoConnector.find_results_for_status status
    end

    def self.all_results
      Mutx::Database::MongoConnector.all_results
    end

    def self.find_all_for_key key
      Mutx::Database::MongoConnector.find_results_for_key key
    end

    # Resets all results with running status
    def self.reset!
      Mutx::Database::MongoConnector.running_results.each do |result|
        Mutx::Support::Processes.kill_p(result["pid"]) if result["pid"]
        res = Mutx::Results::Result.get(result["_id"])
        res.reset!
      end
    end

  end
end