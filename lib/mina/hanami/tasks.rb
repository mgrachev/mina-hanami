require 'mina/deploy'
require 'mina/bundler'

set :hanami_env, 'production'
set :bundle_prefix, -> { %{HANAMI_ENV="#{fetch(:hanami_env)}" #{fetch(:bundle_bin)} exec} }
set :hanami, -> { "#{fetch(:bundle_prefix)} hanami" }

desc 'Starts an interactive console.'
task console: :environment do
  set :execution_mode, :exec
  hanami_command %w(console)
end

namespace :hanami do
  desc 'Migrate database'
  task db_migrate: :environment do
    hanami_command %w(db migrate), 'Migrating database'
  end

  desc 'Precompiles assets (skips if nothing has changed since the last release).'
  task :assets_precompile do
    hanami_command %w(assets precompile), 'Precompiling asset files'
  end
end

def hanami_command(tasks = [], description = nil)
  in_path "#{fetch(:current_path)}" do
    comment description if description
    command %{#{fetch(:hanami)} #{tasks.join(' ')}}
  end
end
