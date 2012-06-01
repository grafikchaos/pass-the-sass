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

  set :sass_dir, '../uploads/'
  set :scss_dir, '../uploads/'

# Index of site
  get '/' do
    @title = "hi there"
    @content = "Welcome to Pass the Sass"
    mustache :index
  end

# Post for site compiles
  post '/compile/?' do
    @title = "Sass Passed - here is your css!"

    @domain = params[:domain]
    @sass = params[:sass]
    @deps = params[:deps]
    @vars = params[:vars]
    @compass = params[:compass]

    mustache :compile
  end


  post '/api/?' do

    # themeName-versionNum
    if params[:domain]
      @domain = params[:domain].to_s + "/"
    end
    if params[:sass]
      @sass = params[:sass]
      @sass_file = params['sass'][:filename]
      @sass_compile = @sass_file[0..-6]
    end
    if params[:deps]
      @deps = params[:deps]
      @deps_num = @deps.length
    end
    if params[:vars]
      @vars = params[:vars]
      @vars_num = @vars.length
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

    # Get only the dependancy file names
    return_keys = [:filename]
    key_index = Hash[return_keys.collect { |key| [key, true] }]
    
    dep_files = @deps.collect do |dep|
      dep.select do |key,value|
        key_index[key]
      end
    end

    # Create directory for this domain
    if @domain
      #Check if the directory exists first
      if File::directory?("uploads/" + @domain)
        #do nothing, the target directory exists
      else
        Dir.mkdir("uploads/" + @domain)
      end
    # Create catch all folder for non domain posts
    else
      if File::directory?("uploads/temp")
        #do nothing cause it exists you joker
      else
        Dir.mkdir("uploads/" + @domain)
      end
      
    end

    # Store stuff in uploads/themeName-versionNum
    if @domain and @type and @sass_file
      File.open('uploads/' + @domain + '/' + @sass_file, "w") do |f|
        f.write(params['sass'][:tempfile].read)
      end
    end
    if @domain and @deps
      @deps.each { |dep, key|
        File.open('uploads/'+ @domain + '/' + dep[:filename], "w") do |f|
          f.write(dep[:tempfile].read)
        end
      }
    end

    if @type == 'sass/'
      sass :"#{@domain}/#{@sass_compile}"
    elsif @type == 'scss/'
      scss :"#{@domain}/#{@sass_compile}"
    else
      "File extension error"
    end


  end

  post '/test/?' do

    # themeName-versionNum
    if params[:domain]
      @domain = params[:domain].to_s + "/"
    end
    if params[:sass]
      @sass = params[:sass]
      @sass_file = params['sass'][:filename]
      @sass_compile = @sass_file[0..-6]
    end
    if params[:deps]
      @deps = params[:deps]
      @deps_num = @deps.length
    end
    if params[:vars]
      @vars = params[:vars]
      @vars_num = @vars.length
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

    # Get only the dependancy file names
    return_keys = [:filename]
    key_index = Hash[return_keys.collect { |key| [key, true] }]
    
    dep_files = @deps.collect do |dep|
      dep.select do |key,value|
        key_index[key]
      end
    end

    # Create directory for posted domain
    if @domain
      #Check if the directory exists first
      if File::directory?("uploads/" + @domain)
        #do nothing, the target directory exists
      else
        Dir.mkdir("uploads/" + @domain)
      end
    # Create catch all folder for non domain posts
    else
      if File::directory?("uploads/temp")
        #do nothing cause it exists you joker
      else
        Dir.mkdir("uploads/" + @domain)
      end
      
    end

    # Store sass file in uploads/themeName-versionNum
    if @domain and @type and @sass_file
      File.open('uploads/' + @domain + '/' + @sass_file, "w") do |f|
        f.write(params['sass'][:tempfile].read)
      end
    end
    # Store dep files in uploads/themeName-versionNum
    if @domain and @deps
      @deps.each { |dep, key|
        File.open('uploads/'+ @domain + '/' + dep[:filename], "w") do |f|
          f.write(dep[:tempfile].read)
        end
      }
    end


    #get files in uploads/themeName-versionNum
    files = Dir["uploads/#{@domain}/*"]
    #parse files & replace vars
    files.each do |file_name|
      text = File.read(file_name)
      if @type = 'scss/'
        # replace vars for scss
        new_content = text.gsub(/\$primary_color(\s)?:(\s)?(.+)/, "$primary_color: ZOMG!")
      elsif @type = 'sass/'
        # replace vars for sass
        new_content = text.gsub(/\$primary_color(\s)?:(\s)?(.+)/, "$primary_color: ZOMG!")
      end
      File.open(file_name, "w") { |file| file.write new_content }
    end
    

    "#{files}"



  end


end