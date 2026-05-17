class DashboardController < ApplicationController
  before_action :require_login

  def index
    service     = TrainingLoadService.new(current_athlete)
    @today      = service.current
    @days_left  = service.days_until_etape
    @form       = @today&.form_status || {}

    @history    = current_athlete.daily_loads.last_n_days(60)
    @chart_data = @history.each_with_object({ ctl: {}, atl: {}, tsb: {} }) do |dl, h|
      h[:ctl][dl.date.strftime("%d/%m")] = dl.ctl
      h[:atl][dl.date.strftime("%d/%m")] = dl.atl
      h[:tsb][dl.date.strftime("%d/%m")] = dl.tsb
    end

    @weekly     = weekly_summary
    @recent     = current_athlete.rides.recent.limit(8)
  end

  def sync
    ActivitySyncService.new(current_athlete).sync!
    redirect_to root_path, notice: "Données mises à jour !"
  rescue => e
    redirect_to root_path, alert: "Erreur sync : #{e.message}"
  end

  private

  def weekly_summary
    max_km = 0
    weeks  = (0..3).map do |w|
      week_end   = Date.today - (w * 7)
      week_start = week_end - 6
      rides = current_athlete.rides.since(week_start.to_time)
                             .where("start_date_local <= ?", week_end.end_of_day)
      km = (rides.sum(:distance) / 1000.0).round(1)
      max_km = km if km > max_km
      {
        label:     w == 0 ? "Cette semaine" : "S-#{w}",
        km:        km,
        elevation: rides.sum(:total_elevation_gain).round,
        hours:     (rides.sum(:moving_time) / 3600.0).round(1),
        count:     rides.count
      }
    end
    [weeks, max_km]
  end
end
