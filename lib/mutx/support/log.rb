module Mutx
	module Support
		class Log
			def self.start
				@@logger ||= Logger.new("#{Dir.pwd}/mutx/logs/mutx.log",1,1024*1024) 
			end

			def self.debug output
				@@logger.debug output
			end

			def self.info output
				@@logger.info output
			end

			def self.error output
				@@logger.error output
			end

		end
	end
end