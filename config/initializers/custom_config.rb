APP_CONFIG = {}

yaml_default = YAML.load(ERB.new(File.read("#{Rails.root}/config/environments/default_config.yml")).result)

APP_CONFIG.merge!(yaml_default) unless yaml_default.blank?

file_name = "#{Rails.root}/config/environments/#{Rails.env}_config.yml"

if File.exist? file_name
  yaml = YAML.load(ERB.new(File.read(file_name)).result)
  APP_CONFIG.merge!(yaml) unless yaml.blank?
end
