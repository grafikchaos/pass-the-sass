require 'sinatra/base'
require 'mustache/sinatra'
require 'sass'
require 'json'
require 'net/http'
require 'uri'

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

    if params[:domain]
      @domain = params[:domain]
    end

    if params[:sass]
      @sass = params[:sass]
    end

    if params['sass'][:filename]
      @sass_file = params['sass'][:filename]
    end

    if params[:deps]
      @dependancies = params[:deps]
    end

    if params[:vars]
      @vars = params[:vars]
    end

    if params[:compass]
      @compass = params[:compass]
    end

    # Figure out which kind of sass file
    if @sass_file and File.extname(@sass_file) == '.sass'
      @type = 'sass/'
    else
      @type = 'scss/'
    end

    if @type
      File.open('uploads/' + @type + @sass_file, "w") do |f|
        f.write(params['sass'][:tempfile].read)
      end
    end


    {"params" => params}.to_json

#    if @type == 'sass/'
#      sass :example
#    elsif @type == 'scss/'
#      scss :example
#    else
#      "File extension error"
#    end
  end
  
  post '/test/?' do
    @url = params[:url]
    url = URI.parse(@url)
    req = Net::HTTP::Get.new(url.path)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    "#{res.body}"
  end
  
end