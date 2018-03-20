class ApplicationController < ActionController::Base
  include Maestrano::Connector::Rails::SessionHelper

  protect_from_forgery with: :exception

  def authenticate_active_admin_user!
    authenticate_or_request_with_http_basic('Admin Connectors') do |username, password|
      ENV['ADMIN_USERNAME'].present? & ENV['ADMIN_PASSWORD'].present? &
        ActiveSupport::SecurityUtils.secure_compare(username, ENV['ADMIN_USERNAME']) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV['ADMIN_PASSWORD'])
    end
  end
end
