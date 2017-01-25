module Mutx
  module Database
    class Middleware

      def initialize(app)
        @app = app
      end
      
      def call(env)
        configuration = Mutx::Support::Configuration.db_connection_data
        Mutx::Database::MongoConnector.new(configuration)
        @app.call(env)
      ensure
        Mutx::Database::MongoConnector.close
      end
    end
  end
end