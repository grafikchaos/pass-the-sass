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


#
# curl 
#
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
        #
        # We already have the proper files, let's just replace vars & recompile!
      else
        # Make the directory!
        Dir.mkdir("uploads/" + @domain)

        # Store the to-be-compiled sass in the directory! (If the domain doesn't exist!)
        if @type and @sass_file
          File.open('uploads/' + @domain + '/' + @sass_file, "w") do |f|
            f.write(params['sass'][:tempfile].read)
          end
        end

        # Store the dependancies in the directory! (If the domain doesn't exist!)
        if @deps
          @deps.each { |dep, key|
            File.open('uploads/'+ @domain + '/' + dep[:filename], "w") do |f|
              f.write(dep[:tempfile].read)
            end
          }
        end
      end

    # Domain wasn't posted - it's required, return error message.
    else
      "Sorry charlie, we need a domain to process your request. Try again!"
    end


    if @type == 'sass/'
      sass :"#{@domain}/#{@sass_compile}-temp"
    elsif @type == 'scss/'
      scss :"#{@domain}/#{@sass_compile}-temp"
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
      @sass_compile = @sass_file[0...-5]
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
        #
        # We already have the proper files, let's just replace vars & recompile!
      else
        # Make the directory!
        Dir.mkdir("uploads/" + @domain)

        # Store the to-be-compiled sass in the directory! (If the domain doesn't exist!)
        if @type and @sass_file
          File.open('uploads/' + @domain + '/' + @sass_file, "w") do |f|
            f.write(params['sass'][:tempfile].read)
          end
        end

        # Store the dependancies in the directory! (If the domain doesn't exist!)
        if @deps
          @deps.each { |dep, key|
            File.open('uploads/'+ @domain + '/' + dep[:filename], "w") do |f|
              f.write(dep[:tempfile].read)
            end
          }
        end
      end

    # Domain wasn't posted - it's required, return error message.
    else
      @output = "Sorry charlie, we need a domain to process your request. Try again!"
    end


    if @domain
      #get files in uploads/themeName-versionNum
      files = Dir["uploads/#{@domain}/*"]
      #parse files & replace vars
      files.each do |file|

        # Set up file variables to work with
        file_content  = File.read(file)
        file_ext      = File.extname(file)
        file_name     = File.basename(file,File.extname(file))


        # Check if type of file is scss
        if file_ext = '.scss'
          # replace vars for scss
          new_content = file_content.gsub(/\$primary_color(\s)?:(\s)?(.+)/, "$primary_color: ZOMG!")
        # Check if type of file is sass
        elsif file_ext = '.sass'
          # replace vars for sass
            new_content = file_content.gsub(/\$primary_color(\s)?:(\s)?(.+)/, "$primary_color: ZOMG!")
        end

        # Check if rewriting the file is worth doing
          if not file_content.eql?(new_content)
          # It is! Make a new file - which we'll call the same but append "temp"
          newfile = File.new("uploads/#{@domain}/#{file_name}-temp#{file_ext}", "w")
          # Open the File we just made, write the new content to the temp file.
          File.open(newfile, "w" ) { |f| f.write new_content }
        end
      end
    end

    "#{@sass}"



  end


end