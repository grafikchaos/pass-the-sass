require 'sinatra/base'
require 'mustache/sinatra'
require 'sass'

class App < Sinatra::Base
  register Mustache::Sinatra
  require 'views/layout'

  set :mustache, {
    :views      => 'views/',
    :templates  => 'templates/'
  }

  helpers do
    def sass(template, *args)
      template = :"#{settings.sass_dir}/#{template}" if template.is_a? Symbol
      super(template, *args)
    end
    def scss(template, *args)
      template = :"#{settings.scss_dir}/#{template}" if template.is_a? Symbol
      super(template, *args)
    end
  end

  set :sass_dir, '../uploads/sass'
  set :scss_dir, '../uploads/scss'


  get '/' do
    @title = "hi there"
    @content = "Welcome to Pass the Sass"
    mustache :index
  end

  post '/compile/?' do
    @title = "Sass Passed - here is your css!"

    @domain = params[:domain]
    @sass = params[:sass]
    @vars = params[:vars]
    @compass = params[:compass]

    mustache :compile
  end


  post '/api/?' do
    @title = "Sass Passed - here is your css!"

    @domain = params[:domain]
    @sass = params[:sass]
    @sass_file = params['sass'][:filename]
    @vars = params[:vars]
    @compass = params[:compass]

    # Figure out which kind of sass file
    if File.extname(@sass_file) == '.sass'
      @type = 'sass/'
    else
      @type = 'scss/'
    end

    File.open('uploads/' + @type + @sass_file, "w") do |f|
      f.write(params['sass'][:tempfile].read)
    end

    if @type == 'sass/'
      sass :example
    elsif @type == 'scss/'
      scss :example
    else
      "File extension error"
    end
  end
  
  get '/test' do
    scss :example
  end
  
end