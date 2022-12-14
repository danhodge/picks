$LOAD_PATH.unshift(File.expand_path('app', File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path('app/models', File.dirname(__FILE__)))

require './simulator'
run Simulator
