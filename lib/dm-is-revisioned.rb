require 'rubygems'
require 'pathname'

gem 'dm-core', '~>0.9.7'
require 'dm-core'

require Pathname(__FILE__).dirname.expand_path / 'dm-is-revisioned' / 'is' / 'revisioned'

# Include the plugin in Resource
module DataMapper
  module Resource
    module ClassMethods
      include DataMapper::Is::Revisioned
    end # module ClassMethods
  end # module Resource
end # module DataMapper
