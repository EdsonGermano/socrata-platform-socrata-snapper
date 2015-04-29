require 'logger'
require 'httparty'
require 'phantomjs'
require 'selenium-webdriver'
require_relative 'utils'

# Class that contains error checking routines
class ErrorCheck
  extend Utils
  attr_accessor :browser, :results

  def initialize()
    @log = Utils::Log.new(true, true)
  end

  # check if a page contains javascript errors.
  # load the page in a browser webdriver with a error collector
  # profile extension
  def javascript_errors(page, log_path="logs")
    errors_found = 0
    errors = ""

    if !Dir.exists?(log_path)
      Dir.mkdir(log_path)
    end

    @log.info("Looking for javascript errors on: #{page}")

    driver = Utils::WebBrowser.new
    driver.browser.navigate.to(page)

    begin
      errors = driver.browser.execute_script("return window.JSErrorCollector_errors ? window.JSErrorCollector_errors.pump() : []")
    rescue => why
      @log.error("Script execution failed. Errors => #{why.message}")
    end

    begin
      if errors.any?
        @log.info('----------------------------------')
        @log.error("Found #{errors.length} javascript errors(s) in page #{page}")
        @log.info('----------------------------------')

        errors.each do |error|
          @log.error("ERROR: " + error["errorMessage"] + " (" + error["sourceName"] + ":" + error["lineNumber"].to_s + ")\n\n")
        end
        errors_found = 1
      else
        @log.info("No errors detected on #{page}")
      end
    rescue => why
      @log.error("Error opening browser for page #{page}. Message #{why.message}")
      errors_found = true
    ensure
      driver.browser.close
    end

    return errors_found
  end

  # check the return code of a particular site.
  # return true if 200, false otherwise
  def page_errors?(page, log_path="logs")
    response_error = false

    if !Dir.exists?(log_path)
      Dir.mkdir(log_path)
    end

    @log.info("Looking for page errors on #{page}")

    begin
      # use httparty
      uri = URI.escape(page)
      response = HTTParty.get(uri)

      if response.header.to_s.include? 'HTTPOK'
        @log.info("Valid response. OK")
      else
        @log.error("Invalid response. #{response.header}")
        response_error = true
      end
    rescue HTTParty::ResponseError => why  #rescue page errors to provide more details and continue
      @log.error("Error response encountered\n#{why.message}")
      response_error = true
    end

    return response_error
  end
end
