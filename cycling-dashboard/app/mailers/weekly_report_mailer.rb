class WeeklyReportMailer < ApplicationMailer
  ETAPE_DATE = Date.new(2026, 7, 19)

  def weekly(athlete)
    @athlete    = athlete
    @days_left  = (ETAPE_DATE - Date.today).to_i
    @today_load = athlete.daily_loads.order(:date).last
    @form       = @today_load&.form_status || {}
    @week_rides = athlete.rides.since((Date.today - 7).to_time)
    @week_km    = (@week_rides.sum(:distance) / 1000.0).round(1)
    @week_elev  = @week_rides.sum(:total_elevation_gain).round
    @week_h     = (@week_rides.sum(:moving_time) / 3600.0).round(1)
    @recent     = athlete.rides.recent.limit(5)

    mail(
      to:      ENV.fetch("REPORT_EMAIL", athlete.firstname),
      subject: "Rapport vélo — J-#{@days_left} avant l'Étape du Tour"
    )
  end
end
