require 'phantomjs'
require 'selenium-webdriver'
#require 'watir-webdriver'
require 'logger'

# Module to do error checking (javascript errors return code errors)
class ErrorCheck
  attr_accessor :browser, :results
  @results = []

  def initialize()
  end

  def javascript_errors(page, log_path, browser=nil)
    errors_found = 0
    errors = ""
    contained = false

    if !Dir.exists?(log_path)
      Dir.mkdir(log_path)
    end

    puts("Looking for javascript errors on: #{page}")
    file = File.open("#{log_path}/javascript_errors.log", "w")
    log = Logger.new(file)

    if browser.nil?
      profile = Selenium::WebDriver::Firefox::Profile.new
      contained = true
      begin
        profile.add_extension("res", "JSErrorCollector.xpi")
        puts("JSErrorCollected loaded")
      rescue => why
        puts("1")
        compound_log("JSErrorCollector failed to load")
        puts("2")
        compound_log("ERROR: #{why.message}")
        puts("3")
      end

      browser = Selenium::WebDriver.for :firefox, :profile => profile
    end

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

      if contained  #need to close if this was not a browser object passed in
        browser.close
      end
    end

    return errors_found
  end

private

  def compound_log(message)
    if @result.nil?
      @result = Array.new
    end
    @result << message.nil? ? "" : message
    puts(message)
  end
end
