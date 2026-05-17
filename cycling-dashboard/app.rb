require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'dotenv/load'

require_relative 'lib/strava_client'
require_relative 'lib/training_calculator'
require_relative 'lib/report_mailer'

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET', SecureRandom.hex(32))
  set :views, File.join(__dir__, 'views')
  set :public_folder, File.join(__dir__, 'public')
end

helpers do
  def strava
    @strava ||= StravaClient.new
  end

  def authenticated?
    strava.authenticated?
  end

  def require_auth
    redirect '/login' unless authenticated?
  end
end

# ── Routes ────────────────────────────────────────────────────────────────────

get '/' do
  require_auth
  activities = strava.cached_activities
  athlete    = session[:athlete] || strava.athlete
  session[:athlete] = athlete

  ftp   = ENV['FTP']&.to_i
  calc  = TrainingCalculator.new(activities, ftp: ftp)
  stats = calc.compute

  erb :dashboard, locals: { stats: stats, athlete: athlete }
end

get '/login' do
  redirect '/' if authenticated?
  erb :login, locals: { auth_url: strava.auth_url }
end

get '/auth/callback' do
  code = params[:code]
  halt 400, 'Code manquant' unless code
  strava.exchange_code(code)
  athlete = strava.athlete
  session[:athlete] = athlete
  strava.fetch_and_cache_activities
  redirect '/'
end

post '/refresh' do
  require_auth
  strava.fetch_and_cache_activities
  redirect '/'
end

post '/report' do
  require_auth
  content_type :json

  activities = strava.cached_activities
  athlete    = session[:athlete] || strava.athlete
  ftp        = ENV['FTP']&.to_i
  stats      = TrainingCalculator.new(activities, ftp: ftp).compute

  begin
    ReportMailer.new(stats, athlete['firstname']).send_weekly_report
    { success: true, message: 'Rapport envoyé !' }.to_json
  rescue => e
    status 500
    { success: false, message: e.message }.to_json
  end
end

get '/logout' do
  strava.logout
  session.clear
  redirect '/login'
end
