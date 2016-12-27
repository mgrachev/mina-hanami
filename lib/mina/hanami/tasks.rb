require 'mina/deploy'
require 'mina/bundler'

set :hanami_env, 'production'
set :bundle_prefix, -> { %{HANAMI_ENV="#{fetch(:hanami_env)}" #{fetch(:bundle_bin)} exec} }
set :hanami, -> { "#{fetch(:bundle_prefix)} hanami" }
set :asset_dirs, ['apps/*/assets/', 'apps/*/vendor/assets/']
set :migration_dirs, ['db/migrations']
set :compiled_asset_path, 'public/assets'

set :shared_files, fetch(:shared_files, []).push('public/assets.json')
set :shared_dirs, fetch(:shared_dirs, []).push(fetch(:compiled_asset_path))

desc 'Starts an interactive console.'
task console: :environment do
  set :execution_mode, :exec
  hanami_command %w(console)
end

namespace :hanami do
  desc 'Migrate database'
  task db_migrate: :environment do

    if fetch(:force_migrate)
      hanami_command %w(db migrate), 'Migrating database'
    else
      command check_for_changes_script(
                  at: fetch(:migration_dirs),
                  skip: %{echo "-----> DB migrations unchanged; skipping DB migration"},
                  changed: %{echo "-----> Migrating database"
                    #{echo_cmd("#{hanami_command(%w(db migrate))}")}}
              ), quiet: true
    end
  end

  desc 'Precompiles assets (skips if nothing has changed since the last release).'
  task :assets_precompile do
    if fetch(:force_asset_precompile)
      hanami_command %w(assets precompile), 'Precompiling asset files'
    else
      command check_for_changes_script(
                  at: fetch(:asset_dirs),
                  skip: %{echo "-----> Skipping asset precompilation"},
                  changed: %{echo "-----> Precompiling asset files"
                    #{echo_cmd("#{hanami_command(%w(assets precompile))}")}}
              ), quiet: true
    end
  end
end

def check_for_changes_script(options)
  diffs = Dir.glob(options[:at]).map do |path|
    %{diff -qrN "#{fetch(:current_path)}/#{path}" "./#{path}" 2>/dev/null}
  end.join(' && ')

  %{
    if #{diffs}
    then
      #{options[:skip]}
    else
      #{options[:changed]}
    fi
  }
end


def hanami_command(tasks = [], description = nil)
  in_path "#{fetch(:current_path)}" do
    comment description if description
    command %{#{fetch(:hanami)} #{tasks.join(' ')}}
  end
end
