<?php
# Get SASSy Goodness
require_once 'PassTheSASS.class.php';

# Obligatory Comment
define('PASS_THE_SASS_DIR', dirname(__FILE__));

/*	Debug Mode
 *	Posts to http://pass-the-sass.herokuapp.com/test/
 *	
 *	Returns posted params
 */
define('PASS_THE_SASS_DEBUG', true);

/*	Graceful Error Mode
 *	Allows use of $sassy->get_errors() method.
 *	
 *	Falls back to PHP die() function for each error. 
 */
define('PASS_THE_SASS_GRACEFUL_ERRORS', true);


# Object Arguments - see PassTheSASS::__construct() for argument documentation
$args = array(
	'sass_path' => PASS_THE_SASS_DIR.'/sass/example.sass',
	'write_path' => PASS_THE_SASS_DIR.'/css/style.css',
	'vars' => array('primary_color' => '#000', 'secondary_color' => '#e3e3e3', 'var3' => '20px'),
	'deps' => array('dependency1.scss', 'dependency2.scss', 'nested-dep.scss'),
	'app' => rand(0, 9999)
);

# Instantiate A SASSy Object
$sassy = new PassTheSASS($args);

# Make SASSy Magic
$result = $sassy->compile();

# Debug that SASSy Mess
$server_response = $sassy->response; // Response from the server
$errors = $sassy->get_errors(); // Works with PASS_THE_SASS_GRACEFUL_MODE