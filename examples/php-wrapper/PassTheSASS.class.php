<?php
/** Pass the SASS Service Integration Class
*	
*	This class includes file/directory checking, request and error handling.
*	One source SASS file and multiple dependencies SASS or SCSS files can be sent to the service.
*	A list of variables are sent to the service to be injected into the output CSS.
*
*	@link https://github.com/LiftUX/pass-the-sass - See our github page for full documentation of the service
*	@link http://pass-the-sass.herokuapp.com/test/ - Debugging API endpoint for returning posted params - Use PASS_THE_SASS_DEBUG to toggle debug endpoint
*	@version 0.1 
*	@author Brian Fegter for UpThemes - http://upthemes.com
*	@license http://opensource.org/licenses/gpl-license.php GNU Public License
*/

if(!class_exists('PassTheSASS')){
    class PassTheSASS{
    	
    	/**
    	* 	API Url
    	*	@link 
    	* 	@var string
    	*/
        private $api = 'http://pass-the-sass.herokuapp.com/api/';
        
        /**
    	* 	SASS Origin File Path
    	* 	@var string
    	*/
        protected $sass_path;
        
        /**
    	* 	SASS Origin File Path
    	* 	@var string
    	*/
        protected $write_path;
        
        /**
    	* 	SASS/SCSS Dependency File Names
    	* 	@var array
    	*/
        protected $deps = array();
        
        /**
    	* 	SASS Variables
    	* 	@var array
    	*/
        protected $vars = array();
        
        /**
    	* 	Application ID (Software Identifier)
    	* 	@var string
    	*/
        protected $app;
        
        /**
    	* 	Unique Identifier (Domain or Server Name)
    	* 	@var string
    	*/
        protected $uid;
        
        /**
    	* 	Debug Mode
    	* 	@var bool
    	*/
        protected $debug = false;
        
        /**
    	* 	Request Post Data
    	* 	@var array
    	*/
        private $post_data;
        
        /**
    	* 	Errors Log
    	* 	@var array
    	*/
        public $errors;
        
        /**
    	* 	Request Response
    	* 	@var string
    	*/
        public $response;
        
        /**
        *	Constructor
        *	
        *	Argument Keys (* Indicates Required)
        *		
        *		sass_path * - (string) - full path to the base SASS file
        *  		write_path * - (string) - full path to the css file to write compiled output
		*  		vars * - (array) - key/value pairs - array('foo'=>'bar', 'foobar'=>'zomg')
		*  		app * - (string) - application name
		*  		deps - (array) - file names - array('file1.sass', 'file2.scss') - Must be sass/scss file types and live as siblings to the origin SASS file
		*  		uid - (string) - domain name - defaults to $_SERVER['SERVER_NAME']
		*  		api - (string) - URL to API endpoint - defaults to http://pass-the-sass.herokuapp.com/api
		*
		*	@param array arguments
		*	@return void
        */
        public function __construct($args){
            $this->_set_vars($args);
        }
        
        /**
        *	Set Class Variables
        *	
        *	Extracts array keys to class variables. Checks for debug mode. Checks if included files and directories exist.
        *
        *	@uses PassTheSASS::__construct param - See arguments documentation
        *	@param array arguments
        *	@return void
        */
        private function _set_vars($args){
            extract($args);
            
            # Set Debug Mode
            if(defined('PASS_THE_SASS_DEBUG')){
	            if(PASS_THE_SASS_DEBUG === true)
	            	$this->debug = true;
	        }
	        
	        # Set API Endpoint
	        if($this->debug)
	        	$api = 'http://pass-the-sass.herokuapp.com/test';
	        else{
            	if(isset($api))
            		$this->api = $api;
            }
            
            # Verify SASS Path
            if(isset($sass_path)){
                $this->sass_path = $sass_path;
                if(!file_exists($this->sass_path))
                    $this->_handle_error('Cannot find SASS file. Please check your path.', 'set_vars');
            }
            else
                $this->_handle_error('Please include the full path to your SASS file.');
            
            # Deps Directory Fallback	
            $this->deps_dir = dirname($sass_path).'/';

            # Set Write Path for CSS Output
            if(is_dir(dirname($write_path)))
                $this->write_path = $write_path;
            else
                $this->_handle_error('Cannot find the output directory. Please check your path.', 'set_vars');
            
            # Set Unique Request Identifier
            $this->uid = isset($uid) ? $uid : $_SERVER['SERVER_NAME'];
            
            # Set Application Identifier
            if(isset($app))
                $this->app = $app ? strtolower(str_replace(' ', '-', $app)) : '';
            else
                $this->_handle_error('SASS application ID must be set.', 'set_vars');
            
            # Validate vars
            if(!$vars)
                $this->_handle_error('SASS vars must be set as an associative array.', 'set_vars');
            elseif(!$this->_is_assoc_array($vars))
                $this->_handle_error('SASS variables must be formatted as a $k => $v pair within an associative array', 'set_vars');
            else
                $this->vars = $vars;
                 
            
            # Set SASS/SCSS Dependencies
            if(is_array($deps))
                foreach($deps as $dep)
                    # Verify the proper formats
                    if(preg_match('/^(.+)\.(scss|sass)$/i', $dep)){
                        # Only add dependencies that exist
                        if(file_exists($this->deps_dir.$dep))
                            $this->deps[] = $dep;
                        else
                            $this->_handle_error('Could not find dependency file: '.$this->deps_dir.$dep, 'set_vars');
                    }
          
        }
    
        /**
        *	Set Post Data for cURL
        *	
        *	Populates the $this->post_data array
        *		sass (string) path to file
        *		vars (array) associative array of key/value pairs
        *		uid (string) unique identifier
        *		app (string) application identifier
        *		
        *	
        *	@return void
        */
        private function _set_post_data(){
        	$post = array();
            
            # Set Dependency Files
            $i = 0;
            if(is_array($this->deps)){
                foreach($this->deps as $dep){
                    $post['deps['.$i.']'] = '@'.$this->deps_dir.$dep;
                    $i++;
                }
            }
            
            # Set SASS Variables
            $i = 0;
            if(is_array($this->vars)){
                foreach($this->vars as $k => $v){
                    $post['vars['.$i.']'] = '$'.$k.': '.$v;
                    $i++;
                }
            }
            
            # Set SASS file
            $post['sass'] = '@'.$this->sass_path;
            
            # Set Unique identifier
            $post['uid'] = $this->uid;
            
            # Set Application identifier
            $post['app'] = $this->app;
            
            # Objectize, yuh.
            $this->post_data = $post;
        }
        
        /**
        *	Send HTTP Request
        * 	Uses $this->post_data and $this->api. Sets public $this->response for debugging
        *	
        *	@return string response
        */
        private function _send_http_request(){
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $this->api);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $this->post_data);
            $response = curl_exec($ch);
            curl_close($ch);
            $this->response = $response;
            return $response;
        }
        
        /**
        *	Write supplied contents to CSS file
        *	@param string file contents
        *	@return bool
        */
        private function _write_to_file($contents){
            return file_put_contents($this->write_path, $contents) ? true : false;
        }
        
        /**
        *	Compile Bootstrap Template Tag
        *	
        *	Publicly visible method for use in application
        *	
        *		Set Post Data - ::_set_post_data()
        *		Send HTTP Request - ::_send_http_request()
        *		Write Contents to File - ::_write_to_file()
        *
        *	@return bool
        */
        public function compile(){		
            $this->_set_post_data();
    
            if($this->errors)
                return false;
            
            $contents = $this->_send_http_request();

            if(!$contents){
                $this->_handle_error('Nothing returned from the server', 'request');
            }
            
            # Do not write debug code to file
            if($this->debug)
            	return;
            
            if($this->_write_to_file($contents))
                return true;
            else{
                $this->_handle_error('Could not write compiled CSS to file.', 'request');
                return false;
            }
        }
        
        /**
        *	Check if Array is Associative
        *	@param array $array
        *	@return string psuedo-bool
        */
        private function _is_assoc_array($array){
            return (count(array_filter(array_keys($array),'is_string')) == count($array));
        }
        
        /**
        *	Error Handling
        *	Checks for graceful error handling. Graceful mode adds errors to a publicly visible array in $this->errors var.
        *	Dies on single error in default mode.
        *	@param string error message
        *	@param string context of error
        *	@return bool
        *	@return die
        */
        private function _handle_error($msg, $context = ''){
            if(defined('PASS_THE_SASS_GRACEFUL_MODE')){
                if(PASS_THE_SASS_GRACEFUL_MODE === true){
                    $this->errors[$context] = $msg;
                    return true;
                }
            }
            die($msg);
        }
        
        /**
        *	API For Getting Errors
        *	@return mixed - false if no errors - array if errors exists
        */
        public function get_errors(){
            if(is_array($this->errors))
                return $this->errors;
            return false;
        }
    }
}