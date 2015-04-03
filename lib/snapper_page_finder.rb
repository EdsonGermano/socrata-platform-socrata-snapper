require 'core/auth/client'
require 'httparty'
require 'json'
require 'uri'

# class to query find the nbe id from an obe id
class PageFinder
  attr_accessor :domain, :email, :password, :auth
  HTTPS = "https://"

  def initialize(_domain, _email, _password, _verify_ssl_cert)
    @email = _email
    @password = _password
    @domain = _domain
    @verify_ssl_cert = _verify_ssl_cert
    @auth = Core::Auth::Client.new(@domain, email: @email, password: @password, verify_ssl_cert: @verify_ssl_cert)

    fail('Authentication failed') unless @auth.logged_in?
  end

  # function to take a obe uri and id and get the nbe id and page id
  def get_nbe_page_id_from_obe_uri(obe_uri_in, obe_id)
    obe_uri = URI(obe_uri_in)
    obe_uri_api = "#{HTTPS}#{obe_uri.host}/api/migrations/#{obe_id}"
    puts("Querying: #{obe_uri_api} for a New UX Id")

    new_ux_id = get_nbe_id_from_obe_domain(obe_uri_api)

    if new_ux_id.nil?
      puts("New UX Id not found")
    else
      puts("New UX Id: #{new_ux_id}")
      new_page = "#{HTTPS}#{obe_uri.host}/view/#{new_ux_id}"

      begin
        puts("Querying: #{new_page} for the contents of the New UX page")
        response = http_get_response(new_page)
        puts("Page: #{new_page} found.")
        new_page
      rescue
        puts("Page: #{new_page} not found.")
        nil
      end
    end
  end

  # get the nbe 4x4 based on an OBE URL
  def get_nbe_id_from_obe_domain(obe_uri)
    uri = URI(obe_uri)
    new_ux_id

    response = http_get_response(uri)
    parsed = response.parsed_response

    puts("New UX Id: #{parsed["nbeId"]}")

    if parsed["nbeId"].nil? || parsed["nbeId"].empty?
    else
      new_ux_id = get_page_id_for_given_nbe_id(uri, parsed["nbeId"])
    end

    new_ux_id
  end

private
  # function to get the page id from a nbe id
  def get_page_id_for_given_nbe_id(uri, nbe_id)
    new_uri = "#{HTTPS}#{uri.host}/metadata/v1/dataset/#{nbe_id}/pages.json"

    response = http_get_response(new_uri)
    parsed = response.parsed_response

    begin
      puts("PageId: #{parsed["publisher"][0]["pageId"]}")
      parsed["publisher"][0]["pageId"]
    rescue
      puts("PageId not found")
    end
  end

  def http_get_response(uri)
    puts("Auth: #{@auth.cookie}\nCalling: #{uri.to_s}")
    response = HTTParty.get(uri, headers: {'Cookie' => @auth.cookie})
  end
end
