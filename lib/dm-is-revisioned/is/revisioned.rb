module DataMapper
  module Is
    ##
    # = Is Revisioned
    # The Revisioned module is similar to Versioned but is sufficiently
    # different that it justified a fork.
    #
    # Just like with Versioned, there is not an incrementing 'version'
    # field, but rather, any field of your choosing which will be unique
    # on update. However, Revisioned will let you specify exactly when a
    # new version should be created. By default, this happens when the record
    # is created or whenever the field you specified changes.
    #
    # == Setup
    # For simplicity, I will assume that you have loaded dm-timestamps to
    # automatically update your :updated_at field. See versioned_spec for
    # and example of updating the versioned field yourself.
    #
    #   class Story
    #     include DataMapper::Resource
    #     property :id, Serial
    #     property :title, String
    #     property :updated_at, DateTime
    #
    #     is_revisioned :on => :updated_at
    #   end
    #
    # == Auto Upgrading and Auto Migrating
    #
    #   Story.auto_migrate! # => will run auto_migrate! on Story::Version, too
    #   Story.auto_upgrade! # => will run auto_upgrade! on Story::Version, too
    #
    # == Usage
    #
    #   story = Story.crreate(:title => "A Title") # Creates a new version
    #   story.versions.size # => 1
    #   story = Story.get(1)
    #   story.title = "New Title"
    #   story.save # Saves this story and creates a new version 
    #   story.versions.size # => 2
    #
    #   story.title = "A Different New Title"
    #   story.save
    #   story.versions.size # => 3
    #
    # == Specifying when a new version should occur
    # You can override the wants_new_version? method to determine exactly when
    # a new version should be created. The method versioned_attribute_changed? 
    # is provided for your convenience, and can be used inside wants_new_version?
    #
    # TODO: enable replacing a current version with an old version.
    module Revisioned
      attr_reader :versioned_property_name

      def is_revisioned(options = {})
        include DataMapper::Is::Revisioned::InstanceMethods
        
        @versioned_property_name = on = options[:on]

        class << self; self end.class_eval do
          define_method :const_missing do |name|
            storage_name = Extlib::Inflection.tableize(self.name + "Version")
            model = DataMapper::Model.new(storage_name)

            if name == :Version
              properties.each do |property|
                options = property.options
                options[:key] = true if property.name == on || options[:serial] == true
                options[:serial] = false
                model.property property.name, property.type, options
              end

              self.const_set("Version", model)
            else
              super(name)
            end
          end
        end

        after_class_method :auto_migrate! do
          self::Version.auto_migrate!
        end

        after_class_method :auto_upgrade! do
          self::Version.auto_upgrade!
        end
        
        before :create, :check_if_wants_new_version
        after  :create, :save_new_version
        
        before :update, :check_if_wants_new_version
        after  :update, :save_new_version
      end


      module InstanceMethods
        ##
        # Returns a hash of original values to be stored in the
        # versions table when a new version is created. It is
        # cleared after a version model is created.
        #
        # --
        # @return <Hash>
        def pending_version_attributes
          @pending_version_attributes ||= {}
        end

        ##
        # Returns a collection of other versions of this resource.
        # The versions are related on the models keys, and ordered
        # by the version field.
        #
        # --
        # @return <Collection>
        def versions(include_current = false)
          query = {}
          version = self.class.const_get("Version")
          self.class.key.zip(self.key) { |property, value| query[property.name] = value }
          query.merge(:order => version.key.collect { |key| key.name.desc })
          result = version.all(query)
        end
        
        def versioned_attribute_changed?
          dirty_attributes.has_key?(self.class.properties[self.class.versioned_property_name])
        end
        
        alias_method :wants_new_version?, :versioned_attribute_changed?
        
        def check_if_wants_new_version
          @should_save_version = wants_new_version?
        end

        def save_new_version(result, *args)
          if result && @should_save_version
            self.class::Version.create(self.attributes) 
            @should_save_version = false
          end
        end
      end
    end # Revisioned
  end # Is
end # DataMapper
