require File.dirname(__FILE__) + "/spec_helper"

if HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES
  describe 'DataMapper::Is::Revisioned', "default behavior" do
    before :all do
      class Story
        include DataMapper::Resource

        property :id, Integer, :serial => true
        property :title, String
        property :updated_at, DateTime

        before :save do
          # For the sake of testing, make sure the updated_at is always unique
          time = self.updated_at ? self.updated_at + 1 : Time.now
          self.updated_at = time if self.dirty?
        end

        is_revisioned :on => :updated_at
      end
    end
    
    after :all do
      if defined?(:Story) then Object.send(:remove_const, :Story) end
    end

    describe "inner class" do
      it "should be present" do
        Story::Version.should be_a_kind_of(Class)
      end

      it "should have a default storage name" do
        Story::Version.storage_name.should == "story_versions"
      end

      it "should have its parent's properties" do
        Story.properties.each do |property|
          Story::Version.properties.should have_property(property.name)
        end
      end
    end # inner class

    describe "#auto_migrate!" do
      before do
        Story::Version.should_receive(:auto_migrate!)
      end
      it "should get called on the inner class" do
        Story.auto_migrate!
      end
    end # #auto_migrate!

    describe "#auto_upgrade!" do
      before do
        Story::Version.should_receive(:auto_upgrade!)
      end
      it "should get called on the inner class" do
        Story.auto_upgrade!
      end
    end # #auto_upgrade!

    describe "#create" do
      before do
        Story.auto_migrate!
        Story.create(:title => "A Very Interesting Article")
      end
      
      it "should create 1 versioned copy" do
        Story::Version.all.size.should == 1
      end
    end # #create

    describe "#save" do
      before do
        Story.auto_migrate!
      end

      describe "(with new resource)" do
        before do
          @story = Story.new(:title => "A Story")
          @story.save
        end
        it "should create 1 versioned copy" do
          Story::Version.all.size.should == 1
        end
      end

      describe "(with a clean existing resource)" do
        before do
          @story = Story.create(:title => "A Story")
          @story.save
        end

        it "should have only 1 versioned copy" do
          Story::Version.all.size.should == 1
        end
      end

      describe "(with a dirty existing resource)" do
        before do
          @story = Story.create(:title => "A Story")
          @story.title = "An Inner Update"
          @story.title = "An Updated Story"
          @story.save
        end

        it "should have 2 versioned copies" do
          Story::Version.all.size.should == 2
        end

        it "should not have the same value for the versioned field" do
          @story.updated_at.should_not == Story::Version.first.updated_at
        end
      end
    end # #save

    describe "#versions" do
      before do
        Story.auto_migrate!
        @story = Story.create(:title => "A Story")
      end

      it "should return a collection when there are versions" do
        @story.versions.should == Story::Version.all(:id => @story.id)
      end

      it "should not return another object's versions" do
        @story2 = Story.create(:title => "A Different Story")
        @story2.title = "A Different Title"
        @story2.save
        @story.versions.should == Story::Version.all(:id => @story.id)
      end
    end # #versions
  end
  
  describe "DataMapper::Is::Versioned", "overriding wants_new_version?" do
    before :all do
      class Story
        include DataMapper::Resource

        property :id, Integer, :serial => true
        property :title, String
        property :updated_at, DateTime

        before :save do
          # For the sake of testing, make sure the updated_at is always unique
          time = self.updated_at ? self.updated_at + 1 : Time.now
          self.updated_at = time if self.dirty?
        end

        is_revisioned :on => :updated_at
        
      end
    end
    
    describe "wants a new version" do
      before do
        Story.class_eval do
          def wants_new_version?
            true # this is dangerous, the key will be the same on 2 consecutive saves, even with no changes
          end
        end
        
        Story.auto_migrate!
        @story = Story.create(:title => "A Story")
      end
      
      it "should create 1 new version" do
        Story::Version.all.size.should == 1
      end
    end
    
    describe "does not want a new version" do
      before do
        Story.class_eval do
          def wants_new_version?
            false
          end
        end
        
        Story.auto_migrate!
        @story = Story.create(:title => "A Story")
      end
      
      it "should not create a new version" do
        Story::Version.all.should be_empty
      end
      
      it "should not create a new version on update" do
        @story.title = "A New Hope"
        @story.save
        Story::Version.all.should be_empty
      end
    end
    
    after :all do
      if defined?(:Story) then Object.send(:remove_const, :Story) end
    end
  end
end
