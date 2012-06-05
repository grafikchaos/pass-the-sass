require 'sinatra/base'
require 'mustache/sinatra'
require 'sass'
require 'compass'

logfile = "pass-the-sass.log"
def pts_log(time,domain,url="none",post)
  if not File.exists?(logfile)
    File.new(logfile, "w")
  end
  url = url == "none" ? "none" : url
  File.open(logfile, "a" ) do  |f|
    f.puts ""
    f.puts "#{time} -- #{url} -- #{domain}"
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

# Use the following string at the command line for simple testing.
#
# curl -F "sass=@examples/example.sass;type=text/css" -F "deps[]=@examples/dependancy1.scss;type=text/css" -F "deps[]=@examples/dependancy2.scss;text/css" -F "deps[]=@examples/nested-dep.scss;type=text/css" -F "vars[]=\$primary_color: #101010" -F "vars[]=\$secondary_color: #F00" -F "vars[]=\$var3: 5px" -F "domain=test-1.0.0" http://localhost:9393/api
 
  post '/api/?' do

    @e_output = String.new

    # themeName-versionNum
    if params[:domain]
      @domain = params[:domain].to_s
    end
    if params[:sass]
      @sass = params[:sass]
      @sass_file = params['sass'][:filename]
      @sass_compile = @sass_file[0...-5]
    end
    if params[:deps]
      @deps = params[:deps]
      @deps_num = @deps.length
      @edited_deps = Array.new
      @dep_files = Array.new
      @deps.each { |dep, key|
        @dep_files.push(dep[:filename])
      }
    end
    if params[:vars]
      @vars = params[:vars]
      @vars_hash = Hash.new
      @vars.each do |x|
        var = x.split(":").first
        value = x.split(":").last
        @vars_hash[var] = "#{value}"
      end 
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


    # Firstly, we need to check if there is a domain,
    # if so, we're going to save the files sent for that domain,
    # if & only if, it doesn't already exist
    # 
    # We need to create a directory for this domain
    if @domain

      #Check if the directory exists first
      if File::directory?("uploads/" + @domain + "/")
        #do nothing, the target directory exists
        #
        # We already have the proper files, let's just move on to replace vars/imports & recompile!
      else
        # Make the directory!
        Dir.mkdir("uploads/" + @domain)

        # Store the to-be-compiled sass in the directory! (Only if the domain doesn't exist!)
        if @type and @sass_file
          File.open('uploads/' + @domain + '/' + @sass_file, "w") do |f|
            f.write(params['sass'][:tempfile].read)
          end
        end
        # Store each dependancy in the directory! (Only if the domain doesn't exist!)
        if @deps
          @deps.each { |dep, key|
            File.open('uploads/'+ @domain + '/' + dep[:filename], "w") do |f|
              f.write(dep[:tempfile].read)
            end
          }
        end

      end
    # Domain wasn't posted - it's required, pass error message.
    else
      @e_output = "Sorry charlie, we need a domain to process your request. Try again!"
    end


    # Parse for Vars
    if @domain

      # First, let's dump old temp files and resave the fresh versions of the current request.
      #
      # Get all the temp directory's files
      temp_dir = "uploads/temp"
      if not File.directory?(temp_dir)
        Dir.mkdir(temp_dir)
      end
      temp_files = Dir["#{temp_dir}/*"]
      # Delete each
      temp_files.each do |temp_file|
        File.delete(temp_file)
      end

      # Then, let's load current request files
      files = Dir["uploads/#{@domain}/*"]
      # Copy those files to temp directory
      files.each do |file|
        # Copy File content
        file_content  = File.read(file)
        file_ext      = File.extname(file)
        file_name     = File.basename(file,file_ext)

        # Make new File in /uploads/temp/ named the same
        File.new("uploads/temp/#{file_name}#{file_ext}", "w")
        # Open that file & write the content we copied
        File.open("uploads/temp/#{file_name}#{file_ext}", "w" ) { |f| f.write file_content }
      end

      # get files in uploads/themeName-versionNum
      temp_files = Dir["uploads/temp/*"]

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

      pts_log(Time.new,params[:domain],params[:url], params)
      sass :"temp/#{@sass_compile}", Compass.sass_engine_options 
    elsif @type == 'scss/'
      pts_log(Time.new,params[:domain],params[:url], params)
      scss :"temp/#{@sass_compile}", Compass.sass_engine_options 
    else
      "#{e_output}"
    end

  end

  post '/test/?' do

    "#{params}"

  end

end