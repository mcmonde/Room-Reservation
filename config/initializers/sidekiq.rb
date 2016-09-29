# job_worker_url = { :url => 'redis://localhost:6379' }

Sidekiq.configure_server do |config|
  config.redis = {url: ENV['JOB_WORKER_URL'], :namespace => "roomreservation"}
end

Sidekiq.configure_client do |config|
  config.redis = {:url => ENV['JOB_WORKER_URL'], :namespace => "roomreservation"}
end
