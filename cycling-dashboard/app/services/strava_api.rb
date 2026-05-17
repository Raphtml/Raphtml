require "faraday"

class StravaApi
  API_BASE  = "https://www.strava.com/api/v3"
  TOKEN_URL = "https://www.strava.com/oauth/token"
  AUTH_URL  = "https://www.strava.com/oauth/authorize"

  def self.auth_url(redirect_uri)
    params = URI.encode_www_form(
      client_id:       ENV.fetch("STRAVA_CLIENT_ID"),
      redirect_uri:    redirect_uri,
      response_type:   "code",
      approval_prompt: "auto",
      scope:           "read,activity:read_all"
    )
    "#{AUTH_URL}?#{params}"
  end

  def self.exchange_code(code, redirect_uri)
    res = Faraday.post(TOKEN_URL, {
      client_id:     ENV.fetch("STRAVA_CLIENT_ID"),
      client_secret: ENV.fetch("STRAVA_CLIENT_SECRET"),
      code:          code,
      grant_type:    "authorization_code",
      redirect_uri:  redirect_uri
    })
    JSON.parse(res.body)
  end

  def initialize(athlete)
    @athlete = athlete
    refresh_token_if_needed!
  end

  def athlete_profile
    get("/athlete")
  end

  def activities(after:, page: 1, per_page: 200)
    get("/athlete/activities", after: after.to_i, page: page, per_page: per_page)
  end

  def all_activities_since(date)
    all  = []
    page = 1
    loop do
      batch = activities(after: date, page: page)
      break unless batch.is_a?(Array) && batch.any?
      all.concat(batch)
      break if batch.size < 200
      page += 1
    end
    all
  end

  private

  def refresh_token_if_needed!
    return unless @athlete.token_expired?

    res  = Faraday.post(TOKEN_URL, {
      client_id:     ENV.fetch("STRAVA_CLIENT_ID"),
      client_secret: ENV.fetch("STRAVA_CLIENT_SECRET"),
      refresh_token: @athlete.refresh_token,
      grant_type:    "refresh_token"
    })
    data = JSON.parse(res.body)
    @athlete.update!(
      access_token:     data["access_token"],
      refresh_token:    data["refresh_token"],
      token_expires_at: data["expires_at"]
    )
  end

  def get(path, params = {})
    conn = Faraday.new(API_BASE)
    res  = conn.get(path) do |req|
      req.headers["Authorization"] = "Bearer #{@athlete.access_token}"
      req.params.merge!(params)
    end
    JSON.parse(res.body)
  end
end
