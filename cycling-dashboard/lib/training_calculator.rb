require 'date'

class TrainingCalculator
  ETAPE_DATE = Date.new(2026, 7, 19)
  CTL_TC     = 42.0
  ATL_TC     = 7.0

  RIDE_TYPES = %w[Ride VirtualRide GravelRide MountainBikeRide].freeze

  def initialize(activities, ftp: nil)
    @activities = activities
    @ftp        = ftp&.to_f
  end

  def compute
    daily_tss = build_daily_tss
    ctl = 0.0
    atl = 0.0
    history = []

    start_date = Date.today - 179
    180.times do |i|
      date = start_date + i
      tss  = daily_tss[date] || 0.0
      ctl  = ctl + (tss - ctl) / CTL_TC
      atl  = atl + (tss - atl) / ATL_TC
      tsb  = ctl - atl
      history << { date: date.to_s, tss: tss.round(1), ctl: ctl.round(1), atl: atl.round(1), tsb: tsb.round(1) }
    end

    current = history.last
    weeks   = weekly_summary

    {
      ctl:               current[:ctl],
      atl:               current[:atl],
      tsb:               current[:tsb],
      form:              form_status(current[:tsb]),
      days_until_etape:  (ETAPE_DATE - Date.today).to_i,
      history:           history,
      weekly_summary:    weeks,
      recent_activities: ride_activities.first(8)
    }
  end

  def form_status(tsb)
    case tsb
    when 25..Float::INFINITY
      { label: 'Très frais',      color: '#3b82f6', bg: '#eff6ff', advice: 'Reposé — parfait avant une compétition ou grosse sortie.' }
    when 5..25
      { label: 'Forme optimale',  color: '#16a34a', bg: '#f0fdf4', advice: 'Pic de forme. Profite pour une sortie qualitative.' }
    when -10..5
      { label: 'Charge normale',  color: '#d97706', bg: '#fffbeb', advice: 'Bonne charge. Surveille ta récupération.' }
    when -25..-10
      { label: 'Fatigué',         color: '#dc2626', bg: '#fef2f2', advice: 'Fatigue accumulée. Récupération conseillée.' }
    else
      { label: 'Surcharge !',     color: '#7c3aed', bg: '#faf5ff', advice: 'Trop de charge. Pause obligatoire.' }
    end
  end

  private

  def ride_activities
    @activities.select { |a| RIDE_TYPES.include?(a['type']) }
               .sort_by { |a| a['start_date'] }
               .reverse
  end

  def build_daily_tss
    cutoff = Date.today - 179
    tss_by_date = {}
    ride_activities.each do |activity|
      date = Date.parse(activity['start_date_local'])
      next if date < cutoff
      tss_by_date[date] = (tss_by_date[date] || 0.0) + estimate_tss(activity)
    end
    tss_by_date
  end

  def estimate_tss(activity)
    moving_time_h = activity['moving_time'].to_f / 3600

    # Power meter + FTP → precise TSS
    if @ftp && @ftp > 0 && activity['weighted_average_watts'].to_i > 0
      np = activity['weighted_average_watts'].to_f
      intensity_factor = np / @ftp
      tss = (moving_time_h * 3600 * np * intensity_factor) / (@ftp * 3600) * 100
      return tss.round(1)
    end

    # Suffer score (HR-based) → approximate TSS
    if activity['suffer_score'].to_i > 0
      return (activity['suffer_score'] * 1.15).round(1)
    end

    # Fallback: duration + elevation heuristic
    elevation     = activity['total_elevation_gain'].to_f
    elev_factor   = 1.0 + (elevation / 1000.0) * 0.25
    (moving_time_h * 52 * elev_factor).round(1)
  end

  def weekly_summary
    weeks = []
    4.times do |w|
      week_end   = Date.today - (w * 7)
      week_start = week_end - 6
      rides = ride_activities.select do |a|
        d = Date.parse(a['start_date_local'])
        d >= week_start && d <= week_end
      end
      weeks << {
        label:     w == 0 ? 'Cette semaine' : "S-#{w}",
        km:        (rides.sum { |a| a['distance'].to_f } / 1000).round(1),
        elevation: rides.sum { |a| a['total_elevation_gain'].to_i },
        hours:     (rides.sum { |a| a['moving_time'].to_i } / 3600.0).round(1),
        count:     rides.size
      }
    end
    weeks
  end
end
