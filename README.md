# Pass the Sass: PHP Class
---

Pass the Sass is a web service that allows you to pass in SASS files in order to generate CSS on the fly.

## Usage

This is PHP Class, built to make talking to Pass the Sass simple. More details to come...

This will exist on the class-php branch, so, to pull down this exclusively if you want to add it as a submodule or put it in your own php application, run `$ git clone -b class-php git@github.com:LiftUX/pass-the-sass.git`


- [View the implementation](https://github.com/LiftUX/pass-the-sass/blob/master/examples/php-wrapper/example.php)

```
require_once 'PassTheSASS.class.php';
define('PASS_THE_SASS_DIR', dirname(__FILE__));

$args = array(
  'sass_path' => PASS_THE_SASS_DIR.'/sass/example.sass',
  'write_path' => PASS_THE_SASS_DIR.'/css/style.css',
  'vars' => array('primary_color' => '#000', 'secondary_color' => '#e3e3e3', 'var3' => '20px'),
  'deps' => array('dependency1.scss', 'dependency2.scss', 'nested-dep.scss'),
  'app' => rand(0, 9999)
);

$sassy = new PassTheSASS($args);
$result = $sassy->compile();
```
