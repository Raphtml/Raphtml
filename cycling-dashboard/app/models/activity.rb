class Activity < ApplicationRecord
  belongs_to :athlete

  RIDE_TYPES = Athlete::RIDE_TYPES

  scope :rides,    -> { where(activity_type: RIDE_TYPES) }
  scope :recent,   -> { order(start_date_local: :desc) }
  scope :since,    ->(date) { where("start_date_local >= ?", date) }

  def distance_km
    (distance / 1000.0).round(1)
  end

  def duration_formatted
    h = moving_time / 3600
    m = (moving_time % 3600) / 60
    "#{h}h#{m.to_s.rjust(2, '0')}"
  end
end
