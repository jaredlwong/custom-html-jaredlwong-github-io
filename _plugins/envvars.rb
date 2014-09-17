# Plugin to add environment variables to the `site` object in Liquid templates

module Jekyll
  class EnvironmentVariablesGenerator < Generator
    def generate(site)
      site.config['dev'] = ENV['DEV'] || nil
    end
  end
end
