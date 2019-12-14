worker_processes 1

before_fork do |_server, _worker|
  sleep 1
end
