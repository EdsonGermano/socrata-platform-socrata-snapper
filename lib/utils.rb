require 'colorize'
require 'logger'
require 'nokogiri'
require 'selenium-webdriver'

# This module will contain utilities for general use by the gem
module Utils
  # A logger class which colorizes console output and writes to console, buffer array and/or file
  class Log
    attr_accessor :log_messages, :log_file

    def initialize(write_file = false, write_array = false, log_level=Logger::INFO, write_log="logger.log")
      @log_messages = Array.new
      @write_to_file = write_file
      @write_to_buffer_array = write_array
      @log_file =  Logger.new(write_log)
      @log_file.level = log_level
      @log_file.info("Writing to log #{write_log}")
    end

    def info(message)
      if @write_to_buffer_array
        @log_messages.push("INFO: #{message}")
      end

      if @write_to_file
        @log_file.info(message)
      end

      puts("INFO: #{message}".green)
    end

    def error(message)
      if @write_to_buffer_array
        @log_messages.push("ERROR: #{message}")
      end

      if @write_to_file
        @log_file.error(message)
      end

      puts("ERROR: #{message}".red)

    end

    def warn(message)
      if @write_to_buffer_array
        @log_messages.push("WARN: #{message}")
      end

      if @write_to_file
        @log_file.warn(message)
      end

      puts("WARN: #{message}".yellow)
    end

    def debug(message)
      if @log_file.level == Logger::DEBUG
        if @write_to_buffer_array
          @log_messages.push("DEBUG: #{message}")
        end

        if @write_to_file
          @log_file.debug(message)
        end

        puts("DEBUG: #{message}".white)
      end
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


    def initialize(add_extension=true, verbose=false)
      http_proxy  = ENV['HTTP_PROXY']
      https_proxy = ENV['HTTPS_PROXY']
      no_proxy    = ENV['NO_PROXY']

      profile = Selenium::WebDriver::Firefox::Profile.new
      verbosity = verbose ? Logger::DEBUG : Logger::INFO
      log = Log.new(true, true, verbosity)

      if http_proxy && https_proxy && no_proxy
          log.debug("Proxy settings present. adding proxy information to browser profile")
          proxy = Selenium::WebDriver::Proxy.new
          proxy.http = HTTP_PROXY.split('://').last
          proxy.ssl = HTTPS_PROXY.split('://').last
          proxy.no_proxy = no_proxy
          profile.proxy = proxy
      end

      if add_extension
        begin
          profile.add_extension("res", "JSErrorCollector.xpi")
          log.debug("JSErrorCollected loaded")
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
