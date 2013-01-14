<?php
/*
Plugin Name: WP Pass The Sass
Plugin URI: http://upthemes.com/plugins/wp-pass-the-sass/
Description: WordPress plugin to make Pass The Sass integration super easy.
Version: 0.0.1
Author: Matthew Simo 
Author URI: http://matthewsimo.com/
*/

define( 'PTS_PLUGIN_PATH', plugin_dir_path( __FILE__ ) );
define( 'PTS_PLUGIN_URL', plugin_dir_url( __FILE__ ) );

# Require the PassTheSass PHP Class Wrapper
require_once( PTS_PLUGIN_PATH . 'Class/PassTheSass.class.php' );

class WP_PassTheSass {

  public function __construct(){

  } 
}
