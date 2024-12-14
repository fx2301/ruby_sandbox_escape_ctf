require 'yaml'

secrets_file = Rails.root.join('config', 'secrets.yml')
if File.exist?(secrets_file)
  secrets = YAML.load(File.read(secrets_file.to_s))
  Rails.application.config.secret_key = secrets['secret_key']
end
