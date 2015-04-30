require 'colorize'
#require 'logger'
require 'nokogiri'
require 'selenium-webdriver'

# This module will contain utilities for general use by the gem
module Utils
  # A logger class which colorizes console output and writes to console, buffer array and/or file
  class Log
    attr_accessor :log_messages, :log_file

    def initialize(write_file = false, write_array = false, write_log="logger.log")
      @log_messages = Array.new
      @write_to_file = write_file
      @write_to_buffer_array = write_array
#      @log_file =  Logger.new(write_log)
#      @log_file.info("Writing to log #{write_log}")
    end

    def info(message)
      if @write_to_buffer_array
        @log_messages.push("INFO: #{message}")
      end

      if @write_to_file
#        @log_file.info(message)
      end

      puts("INFO: #{message}".green)
    end

    def error(message)
      if @write_to_buffer_array
        @log_messages.push("ERROR: #{message}")
      end

      if @write_to_file
#        @log_file.error(message)
      end

      puts("ERROR: #{message}".red)

    end

    def warn(message)
      if @write_to_buffer_array
        @log_messages.push("WARN: #{message}")
      end

      if @write_to_file
#        @log_file.warn(message)
      end

      puts("WARN: #{message}".yellow)
    end

    def clear_message_buffer
      @log_messages.clear
      info("log cleared")
    end

    def dump_log_to_console
      puts("There are: #{@log_messages.count} messages in the log.")

      @log_messages.each do |message|
        if message.include?("INFO")
          puts(message.green)
        elsif message.include?("WARN")
          puts(message.yellow)
        elsif message.include?("ERROR")
          puts(message.red)
        else
          puts("UNKNOWN: #{message}".light_blue)
        end
      end
    end
  end

  # A browser class which returns an intialized browser driver object
  class WebBrowser
    attr_accessor :browser, :extensions_loaded

    def initialize(add_extension=true)
      profile = Selenium::WebDriver::Firefox::Profile.new
      log = Log.new(true, true)

      if add_extension
        begin
          profile.add_extension("res", "JSErrorCollector.xpi")
          log.info("JSErrorCollected loaded")
          @extensions_loaded = "true"
        rescue => why
          log.error("JSErrorCollector failed to load")
          log.error("ERROR: #{why.message}")
        end
      end

      @browser = Selenium::WebDriver.for :firefox, :profile => profile
    end
  end
end
