<?php

# DISCLAIMER - This is still very unstable. Please consider this an alpha implementation.

require_once 'PassTheSASS.class.php';

$args = array(

	# Required
	'sass_path' => '/full/path/to/your/sass/file',
	'write_path' => '/full/path/to/your/output/dir/',
	'vars' => array('var_name' => 'value', 'foo' => 'bar'), // Must be an associative array
	'app' => 'application-name',
	'uid' => 'www.yourdomain.com'

	# Not Required
	#'deps_dir' => '/full/path/to/dependencies/dir/' // Defaults to SASS path directory
	#'deps' => array('file-name.scss', 'file-name.sass') // Must be scss or sass file types
	#'api' => 'http://yourdomain.com/api' // Defaults to http://passthesass.com/api

);

$sassy = new PassTheSASS();
$sassy->compile();