class SessionsController < ApplicationController
  def new
    redirect_to root_path if logged_in?
    @auth_url = StravaApi.auth_url(callback_sessions_url)
  end

  def create
    data = StravaApi.exchange_code(params[:code], callback_sessions_url)

    if data["errors"]
      redirect_to login_path, alert: "Erreur Strava : #{data['message']}"
      return
    end

    athlete_data = data["athlete"]
    athlete = Athlete.find_or_initialize_by(strava_id: athlete_data["id"].to_s)
    athlete.update!(
      firstname:        athlete_data["firstname"],
      lastname:         athlete_data["lastname"],
      profile_medium:   athlete_data["profile_medium"],
      access_token:     data["access_token"],
      refresh_token:    data["refresh_token"],
      token_expires_at: data["expires_at"]
    )

    session[:athlete_id] = athlete.id
    ActivitySyncService.new(athlete).sync!
    redirect_to root_path, notice: "Connecté ! Données synchronisées."
  end

  def destroy
    session.delete(:athlete_id)
    redirect_to login_path
  end
end
