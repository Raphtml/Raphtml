require 'faraday'
require 'json'
require 'fileutils'
require 'uri'

class StravaClient
  API_BASE     = 'https://www.strava.com/api/v3'
  AUTH_URL     = 'https://www.strava.com/oauth/authorize'
  TOKEN_URL    = 'https://www.strava.com/oauth/token'
  TOKENS_FILE  = File.join(__dir__, '..', 'data', 'tokens.json')
  CACHE_FILE   = File.join(__dir__, '..', 'data', 'activities_cache.json')
  HISTORY_DAYS = 180

  def initialize
    @client_id     = ENV.fetch('STRAVA_CLIENT_ID')
    @client_secret = ENV.fetch('STRAVA_CLIENT_SECRET')
    @redirect_uri  = ENV.fetch('STRAVA_REDIRECT_URI', 'http://localhost:4567/auth/callback')
  end

  def auth_url
    params = URI.encode_www_form(
      client_id:     @client_id,
      redirect_uri:  @redirect_uri,
      response_type: 'code',
      approval_prompt: 'auto',
      scope:         'read,activity:read_all'
    )
    "#{AUTH_URL}?#{params}"
  end

  def exchange_code(code)
    res = Faraday.post(TOKEN_URL, {
      client_id:     @client_id,
      client_secret: @client_secret,
      code:          code,
      grant_type:    'authorization_code'
    })
    data = JSON.parse(res.body)
    raise "Strava auth error: #{data['message']}" if data['errors']
    save_tokens(data)
    data
  end

  def authenticated?
    File.exist?(TOKENS_FILE)
  end

  def athlete
    get('/athlete')
  end

  def fetch_and_cache_activities
    after = (Date.today - HISTORY_DAYS).to_time.to_i
    all   = paginate_activities(after: after)
    FileUtils.mkdir_p(File.dirname(CACHE_FILE))
    File.write(CACHE_FILE, JSON.generate({ fetched_at: Time.now.to_i, activities: all }))
    all
  end

  def cached_activities
    return fetch_and_cache_activities unless File.exist?(CACHE_FILE)
    cache = JSON.parse(File.read(CACHE_FILE))
    # Refresh cache if older than 6 hours
    if Time.now.to_i - cache['fetched_at'].to_i > 6 * 3600
      return fetch_and_cache_activities
    end
    cache['activities']
  end

  def logout
    File.delete(TOKENS_FILE) if File.exist?(TOKENS_FILE)
    File.delete(CACHE_FILE)  if File.exist?(CACHE_FILE)
  end

  private

  def paginate_activities(after:)
    all  = []
    page = 1
    loop do
      batch = get('/athlete/activities', after: after, page: page, per_page: 200)
      break unless batch.is_a?(Array) && !batch.empty?
      all.concat(batch)
      break if batch.size < 200
      page += 1
    end
    all
  end

  def access_token
    t = load_tokens
    return nil unless t
    if t['expires_at'].to_i < Time.now.to_i + 60
      refresh_access_token(t['refresh_token'])
    else
      t['access_token']
    end
  end

  def refresh_access_token(refresh_token)
    res  = Faraday.post(TOKEN_URL, {
      client_id:     @client_id,
      client_secret: @client_secret,
      refresh_token: refresh_token,
      grant_type:    'refresh_token'
    })
    data = JSON.parse(res.body)
    save_tokens(data)
    data['access_token']
  end

  def get(path, params = {})
    token = access_token
    conn  = Faraday.new(API_BASE)
    res   = conn.get(path) do |req|
      req.headers['Authorization'] = "Bearer #{token}"
      req.params.merge!(params)
    end
    JSON.parse(res.body)
  end

  def save_tokens(data)
    FileUtils.mkdir_p(File.dirname(TOKENS_FILE))
    File.write(TOKENS_FILE, JSON.generate(data))
  end

  def load_tokens
    return nil unless File.exist?(TOKENS_FILE)
    JSON.parse(File.read(TOKENS_FILE))
  end
end
