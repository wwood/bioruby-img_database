# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
ImgData::Application.initialize!

# Require the stuff in the lib/ directory
require 'bio-img_database'
