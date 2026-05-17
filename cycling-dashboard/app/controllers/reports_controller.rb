class ReportsController < ApplicationController
  before_action :require_login

  def create
    WeeklyReportMailer.weekly(current_athlete).deliver_now
    redirect_to root_path, notice: "Rapport envoyé à #{current_athlete.firstname} !"
  rescue => e
    redirect_to root_path, alert: "Erreur email : #{e.message}"
  end
end
