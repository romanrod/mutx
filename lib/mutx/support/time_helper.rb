# encoding: utf-8
module Mutx
  module Support
    class TimeHelper

      def self.formatted_time_for timestamp
        Time.at(timestamp).strftime(Mutx::Support::Configuration.formatted_datetime)
      end

      def self.start
      	@@start = Time.now.to_i
      end

      def self.elapsed
      	self.now_in_seconds - @@start
      end

      def elapsed_from_last_check_greater_than? senconds
      	raise "seconds arg must be a Fixnum" unless seconds.is_a? Fixnum
      	@@stamp = self.now_in_seconds if @@stamp.nil?
      	if (self.now_in_seconds - @@stamp) > seconds
      		@@stamp = self.now_in_seconds
      		true
      	else
      		false
      	end
      end

      def self.now_in_seconds
      	self.now.to_i
      end

      def self.now
      	Time.now
      end

    end
  end
end