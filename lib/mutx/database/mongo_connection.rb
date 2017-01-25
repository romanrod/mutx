# encoding: utf-8
require 'mongo'

module Mutx
  module Database
    class MongoConnection

      include Singleton

      def client(**args)
        mutex.synchronize {
      	  @client ||= connect_to_database(args)
        }
      end

      def db
      	client.database
      end

      def close
        mutex.synchronize {
          @client.close if @client
          @client = nil
        }
      end

      private

      def mutex
      	@mutex ||= Mutex.new
      end

      def connect_to_database(**args)
      	Mongo::Client.new(hosts(args), database: args[:database])
      	#authenticate(args[:username], args[:pass])
      end

      def hosts(**args)
      	["#{args[:host]}:#{args[:port]}"]
      end

      def authenticate(username, password)
      	self.db.authenticate(username, password)
      end
    end
  end
end
