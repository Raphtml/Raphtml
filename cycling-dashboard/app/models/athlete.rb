class Athlete < ApplicationRecord
  has_many :activities,  dependent: :destroy
  has_many :daily_loads, dependent: :destroy

  RIDE_TYPES = %w[Ride VirtualRide GravelRide MountainBikeRide].freeze

  def rides
    activities.where(activity_type: RIDE_TYPES)
  end

  def token_expired?
    token_expires_at < Time.now.to_i + 60
  end

  def full_name
    "#{firstname} #{lastname}".strip
  end
end
