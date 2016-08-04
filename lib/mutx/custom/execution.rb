# enconding: utf-8
module Mutx
  module Custom
    class Execution

      # This class is used from execution code. It means that user can call this method to store information
      # during exdecution.
      #
      def self.output_path
        "#{Dir.pwd}/mutx/out/ENV['_id']"
      end

      # Returns execution id
      def self.id
        ENV["_id"]
      end

      def self.is_there_result?
        Mutx::Database::MongoConnector.result_data_for_id(self.id)
      end

      # Stores a key => value pair to the result
      # @param [String or Symbol] key
      # @param [Any] value
      # @return hash if stored, nil if not
      def self.add_data key=nil, value=nil
        self.ensure_db_connection
        if self.is_there_result?
          result = self.get_result
          if result and result.running?
            result.add_execution_data key, value if key
            {key => value}
          end
        end
      end

      def self.get_result
        Mutx::Results::Result.get(self.id)
      end

      # Returns result execution data if exist. Else returns an empty hash
      def self.get_data
        self.is_there_result? ? self.get_result.execution_data : {}
      end

      # Conntects to database if not connected
      def self.ensure_db_connection
        Mutx::Support::Configuration.get
        Mutx::Database::MongoConnector.new(Mutx::Support::Configuration.db_connection_data) unless Mutx::Database::MongoConnector.connected?
      end


    end
  end
end