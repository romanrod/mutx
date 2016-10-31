# encoding: utf-8
require 'mutx'
require 'sidetiq'
#require 'sidekiq/testing/inline'

module Mutx
  module Workers
	class StartedTrasher
      include Sidekiq::Worker
      include Sidetiq::Schedulable
      recurrence { minutely(2) }
      def perform
        started_result = nil
        started_result = Mutx::Database::MongoConnector.remove_only_started
		puts "- Started results was removed to avoid problems. -"
        Mutx::Database::MongoConnector.force_close
      end
	end#class
  end
end