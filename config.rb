if defined?(Sinatra)
  # This is the configuration to use when running within sinatra
  project_path = Sinatra::Application.root
  environment = :development
else
  # this is the configuration to use when running within the compass command line tool.
#  css_dir = File.join 'static', 'stylesheets'
  relative_assets = true
  environment = :production
end

css_dir = "public/stylesheets"
output_style = :normal
line_comments = false