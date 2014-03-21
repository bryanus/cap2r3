require "bundler/capistrano"

server "54.193.91.250", :web, :app, :db, primary: true

set :application, "cap2r3"
set :user, "deployer" # The server's user for deploys
set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, "git"
set :repository, "git@github.com:bryanus/#{application}.git" # Your clone URL
set :branch, "master"

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

task :ask_production_confirmation do
  set(:confirmed) do
    puts <<-WARN
 
    ========================================================================
 
      WARNING!! You're about to deploy to PRODUCTION server(s)!!
      Please confirm you know what you are doing.
 ========================================================================
 
    WARN
    answer = Capistrano::CLI.ui.ask "  Are you sure you want to continue? (Y) "
    if answer == 'Y' then true else false end
  end
 
  unless fetch(:confirmed)
    puts "\nDeploy cancelled!"
    exit
  end
end
 
before 'deploy', :ask_production_confirmation


after "deploy", "deploy:cleanup" # keep only the last 5 releases

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      run "/etc/init.d/unicorn_#{application} #{command}"
    end
  end

  task :setup_config, roles: :app do
    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
    sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{application}"
    run "mkdir -p #{shared_path}/config"
    put File.read("config/database.example.yml"), "#{shared_path}/config/database.yml"
    puts "Now edit the config files in #{shared_path}."
  end
  after "deploy:setup", "deploy:setup_config"

  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "deploy:symlink_config"

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/master`
      puts "WARNING: HEAD is not the same as origin/master"
      puts "Run `git push` to sync changes."
      exit
    end
  end
  before "deploy", "deploy:check_revision"
end
