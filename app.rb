require 'sinatra/base'
require 'mustache/sinatra'

class App < Sinatra::Base
  register Mustache::Sinatra
  require 'views/layout'

  set :mustache, {
    :views      => 'views/',
    :templates  => 'templates/'
  }

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
    if (params[:compass] = 'on')
      @compass = TRUE
    else
      @compass = FALSE
    end

    mustache :compile
  end

end