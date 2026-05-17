class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("GMAIL_USER", "noreply@example.com") }
  layout "mailer"
end
