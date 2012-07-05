# Start server for local dev with: "$ bundle exec shotgun -O config.ru"

require 'sinatra/base'
require 'mustache/sinatra'
require 'sass'
require 'compass'

def pts_log(time,app,uid="none",post)
  logfile = "pass-the-sass.log"
  if not File.exists?(logfile)
    File.new(logfile, "w")
  end
  url = url == "none" ? "none" : url
  File.open(logfile, "a" ) do  |f|
    f.puts ""
    f.puts "#{time} -- #{uid} -- #{app}"
    f.puts ""
    f.puts "#{post}"
    f.puts ""
    f.puts "==========================="
  end
end

class App < Sinatra::Base
  register Mustache::Sinatra
  require 'views/layout'

  set :app_file, __FILE__
  set :root, File.dirname(__FILE__)

  set :mustache, {
    :views      => 'views/',
    :templates  => 'templates/'
  }

  configure do
    Compass.add_project_configuration("./config.rb")
  end

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

  set :sass_dir, '../uploads'
  set :scss_dir, '../uploads'

  set :sass, Compass.sass_engine_options
  set :scss, Compass.sass_engine_options

# Index of site
  get '/' do
    @title = "Pass the SASS"
    @content = "Welcome to Pass the SASS"
    mustache :index
  end

# Post for site compiles
  post '/compile/?' do
    @title = "SASS Passed - here is your CSS!"

    @app = params[:app]
    @sass = params[:sass]
    @deps = params[:deps]
    @vars = params[:vars]


    mustache :compile
  end

# Use the following string at the command line for simple testing of the api endpoint.
#
# curl -F "sass=@examples/example.sass;type=text/css" -F "deps[0]=@examples/dependancy1.scss;type=text/css" -F "deps[1]=@examples/dependancy2.scss;text/css" -F "deps[2]=@examples/nested-dep.scss;type=text/css" -F "vars[0]=\$primary_color: #101010" -F "vars[1]=\$secondary_color: #F00" -F "vars[2]=\$var3: 5px" -F "app=test-1.0.0" http://localhost:9393/api 

  post '/api/?' do

    @e_output = String.new

    # themeName-versionNum
    if params[:app]
      @app = params[:app].to_s
    end
    # The sass file to-be-recompiled
    if params[:sass]
      @sass = params[:sass]
      @sass_file = params['sass'][:filename]
      @sass_compile = @sass_file[0...-5]
    end
    # An array of dependancy files
    if params[:deps]
      @deps = params[:deps]
      @deps_num = @deps.length
      @edited_deps = Array.new
      @dep_files = Array.new
      @deps.each { |dep, key|
        @dep_files.push(@deps[dep][:filename])
      }
    end
    # An array of variable strings
    if params[:vars]
      @vars = params[:vars]
      @vars_hash = Hash.new
      @vars.each do |x, y|
        var = y.split(":").first
        value = y.split(":").last
        @vars_hash[var] = "#{value}"
      end 
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

    # Set up directorys we'll be using if they don't exist
    uploads_dir = "uploads"
    temp_dir = "temp"


    if not File.directory?("#{uploads_dir}")
      Dir.mkdir("#{uploads_dir}")
    end
    if not File.directory?("#{uploads_dir}/#{temp_dir}")
      Dir.mkdir("#{uploads_dir}/#{temp_dir}")
    end


    # Firstly, we need to check if there is a domain,
    # if so, we're going to save the files sent for that domain,
    # if & only if, it doesn't already exist
    # 
    # We need to create a directory for this domain
    if @app

      #Check if the directory exists first
      if not File.directory?("#{uploads_dir}/#{@app}")
        # Make the directory!
        Dir.mkdir("#{uploads_dir}/" + @app)
      end

      # Store the to-be-compiled sass in the directory! (Only if the domain doesn't exist!)
      if @type and @sass_file
        File.open("#{uploads_dir}/#{@app}/#{@sass_file}", "w") do |f|
          # Let make sure it's set to @charset "UTF-8"
          f.puts('@charset "UTF-8"')
          # If it's a scss file, add a semicolon and line break, otherwise, just line break
          @type == "scss/" ? f << ";\n" : f << "\n"
          f_content = params['sass'][:tempfile].read
          # Then write the uploaded sass file
          f.write(f_content)
        end

        # Store each dependancy in the directory! (Only if the domain doesn't exist!)
        if @deps
          @deps.each { |dep, key|
            File.open("#{uploads_dir}/#{@app}/#{@deps[dep][:filename]}", "w") do |f|
              f.write(@deps[dep][:tempfile].read)
            end
          }
        end

      end
    # Domain wasn't posted - it's required, pass error message.
    else
      @e_output = "Sorry charlie, we need a domain to process your request. Try again!"
    end


    # Parse for Vars
    if @app

      # First, let's dump old temp files and resave the fresh versions of the current request.
      #
      # Get all the temp directory's files
      temp_files = Dir["#{uploads_dir}/#{temp_dir}/*"]
      # Delete each
      temp_files.each do |temp_file|
        File.delete(temp_file)
      end

      # Then, let's load current request files
      files = Dir["#{uploads_dir}/#{@app}/*"]
      # Copy those files to temp directory
      files.each do |file|
        # Copy File content
        file_content  = File.read(file)
        file_ext      = File.extname(file)
        file_name     = File.basename(file,file_ext)

        # Make new File in /uploads/temp/ named the same
        File.new("#{uploads_dir}/#{temp_dir}/#{file_name}#{file_ext}", "w")
        # Open that file & write the content we copied
        File.open("#{uploads_dir}/#{temp_dir}/#{file_name}#{file_ext}", "w" ) { |f| f.write file_content }
      end

      # get files in uploads/themeName-versionNum
      temp_files = Dir["#{uploads_dir}/#{temp_dir}/*"]

      # Parse for Vars
      #
      # For each file parse, replace vars, write new file, add to edited file array
      temp_files.each do |temp_file|

        # Set up file variables to work with
        temp_file_content  = File.read(temp_file)
        temp_file_ext      = File.extname(temp_file)
        temp_file_name     = File.basename(temp_file,File.extname(temp_file))

        # Assign file contents to a variable so we can track if it's been updated later.
        @new_content = temp_file_content

        # Check if type of file is scss
        if temp_file_ext == '.scss'
          # Parse the file for each var hash key=>value item
          @vars_hash.each{ |key, value|
            # replace vars for scss
            @new_content = @new_content.gsub(/\$(\w+)(\s)?:(\s)?(.+)/) {|s| "$" + $1 == "#{key}" ? "#{key}" + ": #{value}" : s }
          }
        # Check if type of file is sass
        elsif temp_file_ext == '.sass'
          # Parse the file for each var hash key=>value item
          @vars_hash.each{ |key, value|
            # replace vars for sass
            @new_content = @new_content.gsub(/\$(\w+)(\s)?:(\s)?(.+)/) {|s| "$" + $1 == "#{key}" ? "#{key}" + ": #{value}" : s }
          }
        end

        # Check if rewriting the file is even worth doing
        if not temp_file_content.eql?(@new_content)

          # It is! Open the File, write the new content to the temp file.
          File.open(temp_file, "w" ) { |f| f.write @new_content }

        end

      end # files.each do |file|
      #
      # End Parse for Vars

    end # Parse for Vars & Imports

    if @type == 'sass/'
      pts_log(Time.new,params[:app],params[:uid], params)
      content_type 'text/css', :charset => 'UTF-8'
      sass :"temp/#{@sass_compile}", Compass.sass_engine_options 
    elsif @type == 'scss/'
      pts_log(Time.new,params[:app],params[:uid], params)
      content_type 'text/css', :charset => 'UTF-8'
      scss :"temp/#{@sass_compile}", Compass.sass_engine_options 
    else
      "#{e_output}"
    end

  end

  post '/test/?' do

    "#{@params}"

  end

end