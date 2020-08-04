# frozen_string_literal: true

# name: discourse-apple-auth
# about: Enable Login via Apple services aka "Sign-in with Apple"
# version: 0.1
# authors: Robert Barrow
# url: https://github.com/merefield/discourse-apple-auth


gem 'aes_key_wrap', '1.0.1'
gem 'bindata', '2.4.4'
gem 'json-jwt', '1.10.2', { require: false }
gem 'omniauth-apple', '1.0.0'

require 'json/jwt'
require 'omniauth-apple'
require 'auth/oauth2_authenticator'

register_svg_icon "fab-apple" if respond_to?(:register_svg_icon)

enabled_site_setting :sign_in_with_apple_enabled

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
            strategy.options[:info_fields] = 'email,name'
          },
          scope: 'email name'
  end
end

auth_provider icon: 'fab-apple',
              frame_width: 920,
              frame_height: 800,
              authenticator: AppleAuthenticator.new,
              full_screen_login: true

register_css <<CSS

.btn-social.apple {
  background: #000000;
}

CSS
