# encoding: utf-8
module Mutx
  module Support
    module Clean
      def self.start
        Mutx::Tasks.reset!
        Mutx::Results.reset!
        Mutx::Support::FilesCleanner.delete_all_mutx_reports
        Mutx::Support::FilesCleanner.delete_all_console_output_files
      end
    end
  end
end