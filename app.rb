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
      e_output = "Sorry charlie, we need a domain to process your request. Try again!"
    end


    if @type == 'sass/'
      sass :"#{@domain}/#{@sass_compile}-temp"
    elsif @type == 'scss/'
      scss :"#{@domain}/#{@sass_compile}-temp"
    else
      "#{e_output}"
    end


  end

  post '/test/?' do

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

    # We need to create a directory for this domain
    if @domain

      #Check if the directory exists first
      if File::directory?("uploads/" + @domain + "/")
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
      @e_output = "Sorry charlie, we need a domain to process your request. Try again!"
    end


    # Parse for Vars & Imports
    if @domain

      # get files in uploads/themeName-versionNum
      files = Dir["uploads/#{@domain}/*"]
      #make an array to hold edited files so we can parse it later
      temp_files = Array.new

      # Parse for Vars
      #
      # For each file parse, replace vars, write new file, add to edited file array
      files.each do |file|

        # Set up file variables to work with
        file_content  = File.read(file)
        file_ext      = File.extname(file)
        file_name     = File.basename(file,File.extname(file))


        @new_content = file_content
        # Check if type of file is scss
        if file_ext == '.scss'
          @vars_hash.each{ |key, value|
            # replace vars for scss
            @new_content = @new_content.gsub(/\$(\w+)(\s)?:(\s)?(.+)/) {|s| "$" + $1 == "#{key}" ? "#{key}" + ": #{value}" : s }
          }
        # Check if type of file is sass
        elsif file_ext == '.sass'
          @vars_hash.each{ |key, value|
            # replace vars for sass
            @new_content = @new_content.gsub(/\$(\w+)(\s)?:(\s)?(.+)/) {|s| "$" + $1 == "#{key}" ? "#{key}" + ": #{value}" : s }
          }
        end


        # Check if rewriting the file is worth doing
        if not file_content.eql?(@new_content)

          # It is! Make a new file - which we'll call the same but append "temp"
          newfile = File.new("uploads/#{@domain}/#{file_name}-temp#{file_ext}", "w")
          # Open the File we just made, write the new content to the temp file.
          File.open(newfile, "w" ) { |f| f.write @new_content }
          # Let's also add that to the array for files that changed
          temp_files.push("#{file_name}-temp#{file_ext}")
          # We're going to keep track of edited deps for each @import updating
          if @dep_files.include? "#{file_name}#{file_ext}"
            @edited_deps.push("#{file_name}-temp")
          end

        end

      end # files.each do |file|
      #
      # End Parse for Vars


      # Parse Imports
      #
      # We need to parse directory files for any @imports that should be updated.
      files = Dir["uploads/#{@domain}/*"]

      # All your files are belong to parse
      files.each do |file|

        # Set up file variables to work with.
        file_content  = File.read(file)
        file_ext      = File.extname(file)
        file_name     = File.basename(file,File.extname(file))

        @new_content = file_content
        # Check if type of file is scss
        if file_ext == '.scss'
          # replace imports for scss (!!Note the semicolon!!)
          @new_content = @new_content.gsub(/\@import(\s)+("|')(.+)("|')/) {|s|
            if @edited_deps.include? "#{$3}-temp"
              "@import" + $1 + $2 + "#{$3}-temp" + $4 + ";"
            else
              "#{s}"
            end
          }
        # Check if type of file is sass
        elsif file_ext == '.sass'
          # replace imports for sass
          @new_content = @new_content.gsub(/\@import(\s)+("|')(.+)("|')/) {|s|
            if @edited_deps.include? "#{$3}-temp"
              "@import" + $1 + $2 + "#{$3}-temp" + $4
            else
              "#{s}"
            end
          }
        end


        # Check if rewriting the file is worth doing
        if not file_content.eql?(@new_content)

          # Chek if current file is a temp file
          if not temp_files.include? "#{file_name}+#{file_ext}"
            # It's not, let's make a new temp file for it
            newfile = "#{file_name}-temp#{file_ext}"
            # Let's also add that to the array for files that changed
            temp_files.push(newfile)
          else
            # The current file is already a temp file
            newfile = "#{file_name}#{file_ext}"
          end

          # Open the File we will be writing to, write the new content
          File.open("uploads/#{@domain}/#{newfile}", "w" ) { |f| f.write @new_content }
          # We're going to keep track of edited deps for each @import updating
          if @dep_files.include? "#{file_name}" and not @edited_deps.include? "#{newfile}"
            @edited_deps.push("#{newfile}")
          end

        end


      end # files.each do |file|
      #
      # Parse Imports


    end # Parse for Vars & Imports

    "#{temp_files}"


  end


end