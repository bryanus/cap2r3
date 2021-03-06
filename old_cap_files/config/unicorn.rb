root = "/home/mr_deploy/apps/cap2r3/current"
working_directory root
pid "#{root}/tmp/pids/unicorn.pid"
stderr_path "#{root}/log/unicorn.log"
stdout_path "#{root}/log/unicorn.log"

listen "/tmp/unicorn.cap2r3.sock"
worker_processes 2
timeout 30
