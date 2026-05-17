class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  helper_method :current_athlete, :logged_in?

  private

  def current_athlete
    @current_athlete ||= Athlete.find_by(id: session[:athlete_id])
  end

  def logged_in?
    current_athlete.present?
  end

  def require_login
    redirect_to login_path unless logged_in?
  end
end
