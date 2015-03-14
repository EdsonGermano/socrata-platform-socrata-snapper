require 'httparty'
require 'json'
require 'uri'
require 'core/auth/client'

class PageFinder
  attr_accessor :domain, :email, :password, :auth

  def initialize(_domain, _email, _password, _verify_ssl_cert)
    @email = _email
    @password = _password
    @domain = _domain
    @verify_ssl_cert = _verify_ssl_cert
    @auth = Core::Auth::Client.new(@domain, email: @email, password: @password, verify_ssl_cert: @verify_ssl_cert)
    fail('Authentication failed') unless @auth.logged_in?
  end

  # get the nbe 4x4 based on an OBE URL
  def get_nbe_id_from_obe_domain(obe_uri)
    uri = URI(obe_uri)
    puts("Auth: #{@auth.cookie}")
    puts("2 Calling: #{uri.to_s}")

    response = HTTParty.get(uri.to_s, headers: {'Cookie'=> @auth.cookie})
    parsed = response.parsed_response
    puts("Parsed: #{parsed}")
    puts("NBE 4x4: #{parsed["nbeId"]}")
    new_ux_id = ""

    if(!parsed["nbeId"].empty?)
      new_ux_id = get_page_id_for_given_nbe_id(uri, parsed["nbeId"])
    else
      puts("No NBE 4x4 found for this site")
    end

    new_ux_id
  end

  def get_page_id_for_given_nbe_id(uri, nbe_id)
    new_uri = "https://#{uri.host}/metadata/v1/dataset/#{nbe_id}/pages.json"
    #new_uri = URI(preuri)
    puts("3 Calling: #{new_uri}")

    response = HTTParty.get(new_uri, headers: {'Cookie' => @auth.cookie})
    parsed = response.parsed_response
    puts("Parsed: #{parsed}")
    puts("PageId: #{parsed["publisher"][0]["pageId"]}")

    parsed["publisher"][0]["pageId"]
  end

  def get_nbe_page(obe_uri_in, obe_id)
    obe_uri = URI(obe_uri_in)
    obe_uri_api = "https://#{obe_uri.host}/api/migrations/#{obe_id}"
    puts("1 Calling: #{obe_uri_api}")

    new_ux_id = get_nbe_id_from_obe_domain(obe_uri_api)
    puts("New UX id: #{new_ux_id}")
    new_page = "https://#{obe_uri.host}/view/#{new_ux_id}"
    response = HTTParty.get(new_page, headers: {'Cookie' => @auth.cookie})
    new_page
  end
end
