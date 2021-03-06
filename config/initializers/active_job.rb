# thanks, railties/lib/rails/application/bootstrap.rb
logfile = File.open 'log/active_job.log', 'a'
logfile.binmode
logfile.sync = true # if true make sure every write flushes

ajlogger = ActiveSupport::Logger.new(logfile)
ajlogger.formatter = Lograge.formatter # Logger::Formatter.new

ActiveJob::Base.logger = ActiveSupport::TaggedLogging.new(ajlogger)