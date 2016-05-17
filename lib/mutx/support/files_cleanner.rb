require 'fileutils'

module Mutx
  module Support
    class FilesCleanner

      # Delete all mutx_reports html files
      def self.start!
        begin
          self.delete_mutx_reports_dir
        rescue
          false
        end

      end

      def self.delete_file file_name
        begin
          File.delete("#{file_name}") and true
        rescue
          false
        end
      end

      def self.delete_mutx_reports_dir
        location = "#{Dir.pwd}/mutx/mutx_reports"
        FileUtils.rm_rf(location)
        Dir.mkdir(location)
      end

      def self.delete_report_which_has text
        text = text.to_s if text.respond_to? :to_s
        report = all_mutx_reports.select do |file|
          file.include? text
        end.first

        delete_file(report)
      end

      def self.delete_html_report_for result_id
        file = all_mutx_reports.select do |file|
          file.include? result_id
        end.first
        delete_file(file) if file
      end

      def self.all_mutx_reports
        Dir["#{Dir.pwd}/mutx/temp/*.*"].select do |file|
          !file.scan(/mutx_report_\d+\.html/).empty?
        end
      end

      # Deletes all mutx html reports
      def self.delete_mutx_reports
        # Get all html report files
        (Mutx::Support::Git.reset_hard and Mutx::Support::Git.pull) if Mutx::Support::Configuration.use_git?
        begin
          self.delete_all_mutx_reports
        rescue
          false
        end
      end

      # Deletes all mutx html reports files
      # @return [Boolean] if has deleted reports
      def self.delete_all_mutx_reports
        not all_mutx_reports.each do |file|
          self.delete_file(file)
        end.empty?

      end

      # Deletes mutx execution output files
      # @return [Boolean] for success
      def self.delete_console_outputs_files
        (Mutx::Support::Git.reset_hard and Mutx::Support::Git.pull) if Mutx::Support::Configuration.use_git?
        begin
          self.delete_all_console_output_files
          true
        rescue
          false
        end
      end

      # Deletes all mutx execution output files
      # @return [Boolean] if has deleted files
      def self.delete_all_console_output_files
        not all_console_output_reports.each do |file|
          delete_file(file)
        end.empty?
      end

      def self.all_console_output_reports
        Dir["#{Dir.pwd}/mutx/temp/*.*"].select do |file|
          !file.scan(/mutx_co_\d+\.out/).empty?
        end
      end

      def self.delete_console_output_for result_id
        file=all_console_output_reports.select do |file|
          file.include? result_id
        end.first
        delete_file(file) if file
      end

      def self.clear_sidekiq_log
        sidekiq_file_path = "#{Dir.pwd}/mutx/sidekiq_log"
        if File.exist? sidekiq_file_path
          File.delete(sidekiq_file_path)
          File.open(sidekiq_file_path, "a+"){}
        end
      end

      def self.clear_mutx_log
        mutx_log_file_path = "#{Dir.pwd}/mutx/logs/mutx.log"
        if File.exist? mutx_log_file_path
          File.delete(mutx_log_file_path)
          File.open(mutx_log_file_path, "a+"){}
        end
      end

      # Deletes mutx folder. Used by 'bye command'
      # @return [Boolean] for success
      def self.delete_mutx_folder
        begin
          location = "#{Dir.pwd}/mutx"
          FileUtils.rm_rf(location)
          true
        rescue
          false
        end
      end

    end
  end
end