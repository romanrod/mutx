# enconding: utf-8
module Mutx
  module Support
    class TimeHelper

      def self.formatted_time_for timestamp
        Time.at(timestamp).strftime(Mutx::Support::Configuration.formatted_datetime)
      end

    end
  end
end