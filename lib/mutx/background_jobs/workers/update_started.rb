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
        started_result = Mutx::Database::MongoConnector.update_only_started
		puts "- Started results updated to 'NEVER_STARTED' -"
        Mutx::Database::MongoConnector.force_close
      end
	end#class
  end
end