# enconding: utf-8
require 'mutx'

module Mutx
  module Workers
    class EmailSender
      include Sidekiq::Worker
      def perform(result_id)

        puts result_id

        Mutx::Support::Configuration.get
        Mutx::Database::MongoConnector.new Mutx::Support::Configuration.db_connection_data

        result = Mutx::Results::Result.get(result_id)
        puts result

      end
    end
  end
end