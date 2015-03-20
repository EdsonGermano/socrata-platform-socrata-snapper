require 'addressable/uri'
require 'httparty'
require 'nokogiri'

module Core
  module Auth
    class Client
      class << self

        # Creates a new Core::Auth::Client
        #
        # @param domain [String]
        # @param [Hash] options
        # @param options [String] :email
        # @param options [String] :password
        # @param options [String] :cookie An existing auth cookie
        # @param options [Boolean] :verify_ssl_cert Skip SSL verifification
        def new(host, options)
          client_class = Class.new(AbstractClient) do |klass|
            url_host = host.dup
            url_host << ':9443' if url_host.start_with?('localhost')
            url_host = "https://#{url_host}" unless url_host.start_with?('http')
            uri = Addressable::URI.parse(url_host).to_s
            klass.base_uri(uri)
          end
          client_class.new(options)
        end

      end

      class AbstractClient
        include HTTParty
        attr_reader :cookie, :verify_ssl_cert

        def initialize(options = {})
          @verify_ssl_cert = options[:verify_ssl_cert]
          @cookie = options[:cookie]
          login(options[:email], options[:password]) unless @cookie
        end

        # @return [Hash]
        def current_user
          self.class.get('/users/current.json', headers: {'Cookie' => cookie}, verify: verify_ssl_cert)
        end

        def logged_in?
          current_user.include?('id')
        end

        # Allows login with different credentials
        #
        # @param email [String]
        # @param password [String]
        # @return [Core::Auth::Client]
        def login(email, password)
          response = self.class.get('/login', verify: verify_ssl_cert)
          dom = Nokogiri::XML(response.body)
          auth_token = dom.css('//meta[name=csrf-token]')[0].attribute('content').value
          response = self.class.post(
            '/user_sessions',
            body: {
              'user_session[login]' => email,
              'user_session[password]' => password,
              'authenticity_token' => auth_token
            },
            headers: {'Cookie' => response.headers['Set-Cookie']},
            verify: verify_ssl_cert
          )
          @cookie = response.request.options[:headers]['Cookie']
          self
        end
      end
    end
  end
end
