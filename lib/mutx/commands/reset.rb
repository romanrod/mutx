# enconding: utf-8
module Mutx
  module Commands
    def self.reset
      Mutx::Support::Log.debug "#{self}:#{__method__}" if Mutx::Support::Log
      begin

        Mutx::Support::Configuration.get
        Mutx::Database::MongoConnector.new(Mutx::Support::Configuration.db_connection_data)

        print "\nCleanning database..."

        Mutx::Database::MongoConnector.drop_collections
        print "Done!\n\n"

        print "\nCleanning project..."

        Mutx::Support::FilesCleanner.start!
        print "Done!\n\n"

      rescue => e
        puts "CANNOT CLEAN SYSTEM\n#{e}\n\n#{e.backtrace}"
      end
    end
  end
end