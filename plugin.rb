# frozen_string_literal: true

# name: discourse-apple-auth
# about: Enable login via "Sign-in with Apple"
# version: 1.0
# authors: Robert Barrow, David Taylor
# url: https://github.com/discourse/discourse-auth-apple

require_relative "lib/omniauth_apple"

register_svg_icon "fab-apple"

enabled_site_setting :sign_in_with_apple_enabled

register_asset "stylesheets/apple-auth.scss"

after_initialize do
  class ::AppleVerificationController < ::ApplicationController
    skip_before_action :check_xhr, :redirect_to_login_if_required

    def index
      raise Discourse::NotFound unless SiteSetting.apple_verification_txt.present?
      render plain: SiteSetting.apple_verification_txt
    end
  end

  Discourse::Application.routes.append do
    get '/.well-known/apple-developer-domain-association.txt' => "apple_verification#index"
  end
end

class AppleAuthenticator < ::Auth::ManagedAuthenticator
  def name
    'apple'
  end

  def enabled?
    SiteSetting.sign_in_with_apple_enabled?
  end

  def fetch_jwks(options)
    Discourse.cache.fetch("sign-in-with-apple-jwks", expires_in: 1.day) do
      connection = Faraday.new { |c| c.use Faraday::Response::RaiseError }
      JSON.parse(connection.get("https://appleid.apple.com/auth/keys").body, symbolize_names: true)
    end
  rescue Faraday::Error, JSON::ParserError => e
    Rails.logger.error("Unable to fetch sign-in-with-apple-jwks #{e.class} #{e.message}")
    nil
  end

  def register_middleware(omniauth)
    omniauth.provider :apple,
          setup: lambda { |env|
            strategy = env["omniauth.strategy"]
            strategy.options[:client_id] = SiteSetting.apple_client_id
            strategy.options[:team_id] = SiteSetting.apple_team_id
            strategy.options[:key_id] = SiteSetting.apple_key_id
            strategy.options[:pem] = SiteSetting.apple_pem
            strategy.options[:jwk_fetcher] = ->(options) { fetch_jwks(options) }
          }
  end
end

auth_provider icon: 'fab-apple',
              authenticator: AppleAuthenticator.new
