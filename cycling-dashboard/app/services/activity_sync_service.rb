class ActivitySyncService
  SYNC_WINDOW_DAYS = 180

  def initialize(athlete)
    @athlete = athlete
    @api     = StravaApi.new(athlete)
  end

  def sync!
    after = Date.today - SYNC_WINDOW_DAYS
    raw   = @api.all_activities_since(after)
    upsert_activities(raw)
    TrainingLoadService.new(@athlete).recompute!
  end

  private

  def upsert_activities(raw_activities)
    raw_activities.each do |data|
      next unless Athlete::RIDE_TYPES.include?(data["type"])

      activity = @athlete.activities.find_or_initialize_by(strava_id: data["id"])
      activity.assign_attributes(
        name:                    data["name"],
        activity_type:           data["type"],
        start_date:              data["start_date"],
        start_date_local:        data["start_date_local"],
        timezone:                data["timezone"],
        moving_time:             data["moving_time"],
        elapsed_time:            data["elapsed_time"],
        distance:                data["distance"],
        total_elevation_gain:    data["total_elevation_gain"],
        average_watts:           data["average_watts"],
        weighted_average_watts:  data["weighted_average_watts"],
        max_watts:               data["max_watts"],
        average_heartrate:       data["average_heartrate"],
        average_speed:           data["average_speed"],
        suffer_score:            data["suffer_score"],
        trainer:                 data["trainer"] || false
      )
      activity.tss = TssCalculator.call(activity, @athlete.ftp)
      activity.save!
    end
  end
end
