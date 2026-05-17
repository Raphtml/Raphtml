class TrainingLoadService
  CTL_TC     = 42.0
  ATL_TC     = 7.0
  ETAPE_DATE = Date.new(2026, 7, 19)
  WINDOW     = 180

  def initialize(athlete)
    @athlete = athlete
  end

  def recompute!
    # TSS par jour sur la fenêtre
    daily_tss = build_daily_tss

    ctl  = 0.0
    atl  = 0.0
    rows = []

    start_date = Date.today - (WINDOW - 1)
    WINDOW.times do |i|
      date = start_date + i
      tss  = daily_tss[date] || 0.0
      ctl  = ctl + (tss - ctl) / CTL_TC
      atl  = atl + (tss - atl) / ATL_TC

      rows << {
        athlete_id: @athlete.id,
        date:       date,
        tss:        tss.round(2),
        ctl:        ctl.round(2),
        atl:        atl.round(2),
        tsb:        (ctl - atl).round(2),
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    DailyLoad.where(athlete: @athlete).delete_all
    DailyLoad.insert_all!(rows)
  end

  def current
    @athlete.daily_loads.order(:date).last
  end

  def days_until_etape
    (ETAPE_DATE - Date.today).to_i
  end

  private

  def build_daily_tss
    cutoff = Date.today - (WINDOW - 1)
    @athlete.activities
            .rides
            .since(cutoff.to_time)
            .each_with_object(Hash.new(0.0)) do |a, h|
              h[a.start_date_local.to_date] += a.tss.to_f
            end
  end
end
