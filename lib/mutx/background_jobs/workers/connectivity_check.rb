# encoding: utf-8
require 'mutx'
require 'sidetiq'
require 'open-uri'
#require 'sidekiq/testing/inline'

module Mutx
  module Workers
    class ConnectivityCheck
      include Sidekiq::Worker
      include Sidetiq::Schedulable
        recurrence { minutely(2) }
        def perform
          Mutx::Database::MongoConnector.new Mutx::Support::Configuration.db_connection_data
        #def self.check
          path = "#{Dir.pwd}/mutx/temp/connectivity_check.txt"
          message_lost = "Internet connection lost!"
          begin
            if open("http://www.google.com/")
              contents = File.read("#{path}") if File.file?("#{path}")
              Mutx::Support::MailSender.new.sender(nil, "No internet connection for a while, now is ready again", "ohamra@gmail.com", "Prueba", nil, nil, nil, nil, nil) if ( (!contents.nil?) && (contents.include? "#{message_lost}") )
              File.delete("#{path}") if File.file?("#{path}")
            else
              raise StandardError.new "#{message_lost}"
            end
          rescue StandardError => e
            output = File.open("#{path}", "a+")
            text = "#{Time.now} - #{e.message}"
            output.puts "#{text}"
            output.close
          end
        end
    end#class
  end
end