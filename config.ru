$:.unshift(__FILE__, ".")

require 'app'
require 'sass'

use Rack::ShowExceptions

run App.new