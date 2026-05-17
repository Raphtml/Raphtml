class TssCalculator
  def self.call(activity, ftp)
    new(activity, ftp).call
  end

  def initialize(activity, ftp)
    @activity = activity
    @ftp      = ftp&.to_f
  end

  def call
    moving_time_h = @activity.moving_time.to_f / 3600
    return 0.0 if moving_time_h <= 0

    # Power meter + FTP → TSS précis (IF²  × durée_h × 100)
    if @ftp&.> 0 && @activity.weighted_average_watts.to_i > 0
      np = @activity.weighted_average_watts.to_f
      intensity_factor = np / @ftp
      return (moving_time_h * 3600 * np * intensity_factor / (@ftp * 3600) * 100).round(2)
    end

    # Suffer Score Strava (HR-based) → approximation
    if @activity.suffer_score.to_i > 0
      return (@activity.suffer_score * 1.15).round(2)
    end

    # Fallback : durée × dénivelé
    elevation    = @activity.total_elevation_gain.to_f
    elev_factor  = 1.0 + (elevation / 1000.0) * 0.25
    (moving_time_h * 52 * elev_factor).round(2)
  end
end
