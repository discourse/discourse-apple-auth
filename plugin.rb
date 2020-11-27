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

  def register_middleware(omniauth)
    omniauth.provider :apple,
          setup: lambda { |env|
            strategy = env["omniauth.strategy"]
            strategy.options[:client_id] = SiteSetting.apple_client_id
            strategy.options[:team_id] = SiteSetting.apple_team_id
            strategy.options[:key_id] = SiteSetting.apple_key_id
            strategy.options[:pem] = SiteSetting.apple_pem
          }
  end
end

auth_provider icon: 'fab-apple',
              authenticator: AppleAuthenticator.new
