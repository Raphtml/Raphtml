class ActivitiesController < ApplicationController
  before_action :require_login

  def index
    @activities = current_athlete.rides.recent.page(params[:page]).per(20)
    @total_km   = (current_athlete.rides.sum(:distance) / 1000.0).round(0)
    @total_elev = current_athlete.rides.sum(:total_elevation_gain).round(0)
    @total_h    = (current_athlete.rides.sum(:moving_time) / 3600.0).round(1)
  end
end
