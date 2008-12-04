require 'rubygems'
require 'spec'
require 'spec/rake/spectask'
require 'pathname'
require 'hoe'

ROOT = Pathname(__FILE__).dirname.expand_path
require ROOT + 'lib/dm-is-revisioned/is/version'

AUTHOR = "David Leal"
EMAIL  = "dgleal@gmail.com"
GEM_NAME = "dm-revisioned"
GEM_VERSION = DataMapper::Is::Revisioned::VERSION
GEM_DEPENDENCIES = [['dm-core', "~> 0.9.7"]]
GEM_CLEAN = ["log", "pkg"]
GEM_EXTRAS = { :has_rdoc => true, :extra_rdoc_files => %w[ README.txt LICENSE TODO ] }

PROJECT_NAME = "dm-is-revisioned"
PROJECT_URL  = "http://github.com/david/dm-is-revisioned"
PROJECT_DESCRIPTION = PROJECT_SUMMARY = "DataMapper plugin enabling more flexible versioning of models"

hoe = Hoe.new(GEM_NAME, GEM_VERSION) do |p|

  p.developer(AUTHOR, EMAIL)

  p.description = PROJECT_DESCRIPTION
  p.summary = PROJECT_SUMMARY
  p.url = PROJECT_URL

  p.rubyforge_name = PROJECT_NAME if PROJECT_NAME

  p.clean_globs |= GEM_CLEAN
  p.spec_extras = GEM_EXTRAS if GEM_EXTRAS

  GEM_DEPENDENCIES.each do |dep|
    p.extra_deps << dep
  end
end

task :default => [ :spec ]

WIN32 = (RUBY_PLATFORM =~ /win32|mingw|cygwin/) rescue nil
SUDO  = WIN32 ? '' : ('sudo' unless ENV['SUDOLESS'])

desc "Install #{GEM_NAME} #{GEM_VERSION} (default ruby)"
task :install => [ :package ] do
  sh "#{SUDO} gem install --local pkg/#{GEM_NAME}-#{GEM_VERSION} --no-update-sources", :verbose => false
end

desc "Uninstall #{GEM_NAME} #{GEM_VERSION} (default ruby)"
task :uninstall => [ :clobber ] do
  sh "#{SUDO} gem uninstall #{GEM_NAME} -v#{GEM_VERSION} -I -x", :verbose => false
end

namespace :jruby do
  desc "Install #{GEM_NAME} #{GEM_VERSION} with JRuby"
  task :install => [ :package ] do
    sh %{#{SUDO} jruby -S gem install --local pkg/#{GEM_NAME}-#{GEM_VERSION} --no-update-sources}, :verbose => false
  end
end

desc 'Run specifications'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts << '--options' << 'spec/spec.opts' if File.exists?('spec/spec.opts')
  t.spec_files = Pathname.glob((ROOT + 'spec/**/*_spec.rb').to_s)

  begin
    t.rcov = ENV.has_key?('NO_RCOV') ? ENV['NO_RCOV'] != 'true' : true
    t.rcov_opts << '--exclude' << 'spec'
    t.rcov_opts << '--text-summary'
    t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
  rescue Exception
    # rcov not installed
  end
end
