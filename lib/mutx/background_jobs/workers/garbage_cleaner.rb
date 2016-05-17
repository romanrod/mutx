require 'mutx'

module Mutx
  module Workers
    class GarbageCleaner

      # This worker delete all zombies files
      include Sidekiq::Worker
        def perform

          Mutx::Support::Configuration.get
          Mutx::Database::MongoConnector.new(Mutx::Support::Configuration.db_connection_data)

          get_present_output_files = Dir["#{Dir.pwd}/mutx/temp/*.out"].select{|file|  file.start_with? "mutx_co_"}
          get_present_report_files = Dir["#{Dir.pwd}/mutx/temp/*.html"].select{|file|  file.start_with? "mutx_report_"}

          get_present_output_files.each do |output_file|
            if result = Mutx::Results::Result.get(output_file.scan(/\d+/).first)
              File.delete("#{Dir.pwd}/mutx/temp/#{output_file}") if result.finished?
            end
          end

          get_present_report_files.each do |report_file|
            if result = Mutx::Results::Result.get(report_file.scan(/\d+/).first)
              File.delete("#{Dir.pwd}/mutx/temp/#{report_file}") if result.finished?
            end
          end
        end
    end
  end
end
