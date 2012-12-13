current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "jritorto"
client_key               "#{current_dir}/jritorto.pem"
validation_client_name   "modcloth-ebs-validator"
validation_key           "#{current_dir}/modcloth-ebs-validator.pem"
chef_server_url          "https://api.opscode.com/organizations/modcloth-ebs"
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            ["#{current_dir}/../cookbooks"]
