# encoding: utf-8
require 'mutx'
require 'sidetiq'
#require 'sidekiq/testing/inline'

module Mutx
  module Workers
	class UpdateStarted
      include Sidekiq::Worker
      include Sidetiq::Schedulable
      recurrence { minutely(2) }
      def perform
        started_result = nil
        started_result = Mutx::Database::MongoConnector.started!
        started_result.each do |line|
          puts Mutx::API::Execution.reset(line["_id"])
        end
        puts "- ==== NO Started Results Founded ====" if started_result.eql? []
        ##Mutx::Database::MongoConnector.force_close
      end
	end#class
  end
end