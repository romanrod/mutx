# encoding: utf-8
module Mutx
  module Support
    module Logs

      def self.path
        "#{Dir.pwd}/mutx/"
      end

      def self.all
        logs = Hash.new
        Dir.glob(path + '*.log') do |log_file|
          name = log_file.split("/").last.gsub('.log','')
          text = File.read(log_file)
          logs[name] = text
        end
        logs
      end

      def self.read_log_file_content_for log=nil
          path = "#{Dir.pwd}/mutx/logs/#{log}.log"
          if File.exist?("#{path}")
            FileUtils.cp(path, "#{path}~")
            all_content = IO.read("#{path}~")
            content = all_content.gsub("\n","<br>")
            File.delete("#{path}~")
          else
            content = ""
          end
          content
      end
    end
  end
end