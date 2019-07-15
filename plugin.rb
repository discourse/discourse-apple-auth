# frozen_string_literal: true

# name: discourse-apple-auth
# about: Enable Login via Apple services aka "Sign-in with Apple"
# version: 0.1
# authors: Robert Barrow
# url: https://github.com/merefield/discourse-apple-auth


gem 'aes_key_wrap', '1.0.1'
gem 'bindata', '2.4.4'
gem 'json-jwt', '1.10.2', { require: false }
gem 'omniauth-apple', '0.0.1'

require 'auth/oauth2_authenticator'
require 'json-jwt'

register_svg_icon "fab-apple" if respond_to?(:register_svg_icon)

enabled_site_setting :sign_in_with_apple_enabled

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
            strategy.options[:private_key] = SiteSetting.apple_private_key
            strategy.options[:info_fields] = 'email, name'
         },
         scope: 'email name'
  end
end

auth_provider icon: 'fab-apple',
              frame_width: 920,
              frame_height: 800,
              authenticator: AppleAuthenticator.new

register_css <<CSS

.btn-social.apple {
  background: #000000;
}

CSS
