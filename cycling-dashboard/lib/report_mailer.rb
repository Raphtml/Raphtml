require 'net/smtp'
require 'date'

class ReportMailer
  def initialize(stats, athlete_name)
    @stats        = stats
    @athlete_name = athlete_name
    @to           = ENV.fetch('REPORT_EMAIL')
    @from         = ENV.fetch('GMAIL_USER')
    @password     = ENV.fetch('GMAIL_APP_PASSWORD')
  end

  def send_weekly_report
    message = build_message
    Net::SMTP.start('smtp.gmail.com', 587, 'localhost', @from, @password, :login) do |smtp|
      smtp.send_message(message, @from, @to)
    end
    true
  rescue => e
    raise "Erreur envoi email : #{e.message}"
  end

  private

  def build_message
    s    = @stats
    form = s[:form]
    week = s[:weekly_summary].first

    subject = "Rapport vélo — J-#{s[:days_until_etape]} avant l'Étape du Tour"

    body = <<~TEXT
      Bonjour #{@athlete_name},

      ═══════════════════════════════════════
      RAPPORT HEBDOMADAIRE — #{Date.today.strftime('%d/%m/%Y')}
      ═══════════════════════════════════════

      🏁 Étape du Tour 2026 : J-#{s[:days_until_etape]}

      ── FORME DU MOMENT ──────────────────
      Statut   : #{form[:label]}
      CTL      : #{s[:ctl]} (forme chronique sur 42j)
      ATL      : #{s[:atl]} (fatigue aiguë sur 7j)
      TSB      : #{s[:tsb]} (fraîcheur = CTL - ATL)

      #{form[:advice]}

      ── SEMAINE EN COURS ─────────────────
      Sorties  : #{week[:count]}
      Distance : #{week[:km]} km
      Dénivelé : #{week[:elevation]} m
      Durée    : #{week[:hours]} h

      ── DERNIÈRES SORTIES ────────────────
      #{format_activities}
      ═══════════════════════════════════════
      Dashboard : http://localhost:4567
      ═══════════════════════════════════════
    TEXT

    <<~EMAIL
      From: Dashboard Vélo <#{@from}>
      To: #{@to}
      Subject: #{subject}
      MIME-Version: 1.0
      Content-Type: text/plain; charset=UTF-8

      #{body}
    EMAIL
  end

  def format_activities
    @stats[:recent_activities].first(5).map do |a|
      date = Date.parse(a['start_date_local']).strftime('%d/%m')
      dist = (a['distance'].to_f / 1000).round(1)
      elev = a['total_elevation_gain'].to_i
      time = format_duration(a['moving_time'].to_i)
      "  #{date}  #{a['name'].ljust(30)}  #{dist.to_s.rjust(5)} km  #{elev.to_s.rjust(4)} m D+  #{time}"
    end.join("\n")
  end

  def format_duration(seconds)
    h = seconds / 3600
    m = (seconds % 3600) / 60
    "#{h}h#{m.to_s.rjust(2, '0')}"
  end
end
