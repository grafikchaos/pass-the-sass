# Pass the Sass
---

Pass the Sass is a web service that allows you to pass in SASS files in order to generate CSS on the fly.

## Here is the problem
We've got some PHP products (WP themes) that we use sass to make maintaining our code easy but we can't be sure of server capability when the themes are running. This is an issue because we want to only serve one file for our styles, even if our user's edit theme options that directly influence theme specific sass variables.



## Getting started!

This is a fairly simple, straight forward sinatra app, you've got a couple of options.

You can just send a POST to our endpoint at [http://pass-the-sass.herokuapp.com/api](http://pass-the-sass.herokuapp.com/api), which is what we would probably recommend.

OR, you could fork it and run it yourself.. If you want to do that, a couple of things that will be useful are `bundle install` & `bundle exec shotgun -O config.ru`. This will install any/all dependancies you're missing (assuming you have ruby & gem already installed) and start an instance of the server running on localhost:9393/



## API stuff


The endpoint that matters is at `/api/` - you'll make a POST with the following parameters:

- sass    (A .sass|.scss file - this is what we're compiling.)
- app     (A "unique" request identifier (Theme-Version))
- deps    (An array of deps (your sass includes))
- vars    (An array of strings you wanna update!)
- uid     (Universal ID - (URL))


### sass

Your sass or scss file. Put it in the sass parameter.

### app

You'll post a somewhat arbitrary identifer for the requesting application - upthemes intends to use ThemeName-VersionNumber - This will enable us to cache requests and only parse > replace > recompile and save a lot of leg work for compilation request for the same version number of a particular theme.

### deps[]

Post an array of your sass dependancies. Handles as many as you need, and automagically checks for compass so don't worry about passing those in...

### vars[]

Pass an array of files you want to update. We do some rudimentary checking here, but it's nothing too robust, use your sass|scss syntax and you'll be good to go. See the example for some more info.

### uid

This is mostly for internal use, to track what themes/locations requests are coming from. It's an arbitrary identifier mostly that relates to the URL it's coming from..



### Examples

#### Unix CLI curl:

First - clone this repo:

`$ git clone git://github.com/LiftUX/pass-the-sass.git`

Then, `cd pass-the-sass`, `bundle install` and start the server `bundle exec shotgun -O config.ru`

Once the server is running, run an example curl that uses the files in the examples directory:

`$ curl -F "sass=@examples/example.sass;type=text/css" -F "deps[0]=@examples/dependancy1.scss;type=text/css" -F "deps[1]=@examples/dependancy2.scss;text/css" -F "deps[2]=@examples/nested-dep.scss;type=text/css" -F "vars[0]=\$primary_color: #101010" -F "vars[1]=\$secondary_color: #F00" -F "vars[2]=\$var3: 5px" -F "app=test-1.0.0" http://localhost:9393/api`


#### PHP curl:

```

$url = 'http://localhost:9393/api';
$post = array(
  "domain"  => THEME_NAME . "-" . THEME_VERSION,
  "sass"    => "@examples/examples.sass",

  "deps[0]"  => "@$examples/_flexslider.scss\",
  "deps[1]"  => "@examples/_grind.scss\",
  "deps[2]"  => "@$examples/_icons.scss\",
  "deps[3]"  => "@examples/_normalize.scss/",

  "vars[0]"   => "\$body-color: #333",
  "vars[1]"   => "\$accent-color: #F00"
);

  $ch = curl_init();
  
  curl_setopt($ch, CURLOPT_URL, $url);
  curl_setopt($ch, CURLOPT_POST, true);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $post);

  $response = curl_exec($ch);
  curl_close($ch);
  
```

Then, you'd want to build how your app handles `$response`. Which on success, returns the recompiled css but with your updated vars.


## Where we're headed

First thing to understand, this is a tool we're building for an internal problem. You want a specific feature, fork it and send us a pull request, we'll love collaborating with you... we're just a little busy.

###Thoughts, ideas, and soft-plans:

- We want to just accept a serialized string of data for all the files for performance reasons.
- Support an options parameters that handles any sass command line options you might wanna send.
- PHP Class that we'll be implementing into the [Uptheme Framework](https://github.com/LiftUX/UpThemes-Framework/tree/settings-api) that makes creating/handling requests on theme option updates in a wordpress installtion super simple.
- AND MOOAAARRRR!




