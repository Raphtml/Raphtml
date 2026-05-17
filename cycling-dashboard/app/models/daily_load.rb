class DailyLoad < ApplicationRecord
  belongs_to :athlete

  scope :ordered,    -> { order(:date) }
  scope :last_n_days, ->(n) { where("date >= ?", Date.today - n).ordered }

  def form_status
    case tsb
    when 25..Float::INFINITY then { label: "Très frais",     color: "blue",   advice: "Reposé — parfait avant une compétition." }
    when 5..25               then { label: "Forme optimale", color: "green",  advice: "Pic de forme. Profite pour une sortie qualitative." }
    when -10..5              then { label: "Charge normale", color: "yellow", advice: "Bonne charge. Surveille ta récupération." }
    when -25..-10            then { label: "Fatigué",        color: "red",    advice: "Fatigue accumulée. Récupération conseillée." }
    else                          { label: "Surcharge !",    color: "purple", advice: "Trop de charge. Pause obligatoire." }
    end
  end
end
