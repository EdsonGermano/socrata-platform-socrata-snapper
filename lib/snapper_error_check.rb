require 'logger'
require 'httparty'
require 'phantomjs'
require 'selenium-webdriver'

# Class that contains error checking routines
class ErrorCheck
  attr_accessor :browser, :results
  @results = []

  def initialize()
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

    puts("Looking for javascript errors on: #{page}")
    file = File.open("#{log_path}/javascript_errors.log", "a")
    log = Logger.new(file)

    profile = Selenium::WebDriver::Firefox::Profile.new

    begin
      profile.add_extension("res", "JSErrorCollector.xpi")
      puts("JSErrorCollected loaded")
    rescue => why
      compound_log("JSErrorCollector failed to load")
      compound_log("ERROR: #{why.message}")
    end

    browser = Selenium::WebDriver.for :firefox, :profile => profile
    browser.navigate.to(page)

    begin
      errors = browser.execute_script("return window.JSErrorCollector_errors ? window.JSErrorCollector_errors.pump() : []")
    rescue => why
      puts("Script execution failed. Errors => #{why.message}")
    end

    begin
      if errors.any?
        log.info('----------------------------------')
        log.error("Found #{errors.length} javascript errors(s) in page #{page}")
        log.info('----------------------------------')

        compound_log("Found #{errors.length} javascript errors(s) in page #{page}\n")

        errors.each do |error|
          compound_log("ERROR: " + error["errorMessage"] + " (" + error["sourceName"] + ":" + error["lineNumber"].to_s + ")\n\n")
        end
        log.close
        errors_found = 1
      else
        log.info("No errors detected on #{page}")
        compound_log("No errors detected on #{page}")
      end
    rescue => why
      log.error("Error opening browser for page #{page}. Message #{why.message}")
      compound_log("Error opening browser for page #{page}. Message #{why.message}")
      errors_found = true
    ensure
      file.close
      log.close
      browser.close
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

    puts("Looking for page errors on #{page}")
    file = File.open("#{log_path}/page_errors.log", "a")
    log = Logger.new(file)

    begin
      # use httparty
      response = HTTParty.get(page)

      if response.header.to_s.include? 'HTTPOK'
        puts("Valid response. OK")
      else
        puts("Invalid response. #{response.header}")
        response_error = true
      end
    rescue => why
      puts("Error response encountered\n#{why.message}")
      response_error = true
    end

    return response_error
  end

private
  # logging redirect to a message array for later flushing and to console.
  def compound_log(message)
    if @result.nil?
      @result = Array.new
    end
    @result << message.nil? ? "" : message
    puts(message)
  end
end
