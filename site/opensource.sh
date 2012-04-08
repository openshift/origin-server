# run from the the li/ dir
pushd ..

git clone --no-hardlinks li console
cd console/
git checkout master

# Preserve selenium
git mv selenium/Gemfile site/test/Gemfile_old
git mv selenium/Gemfile.lock site/test/Gemfile_old.lock
git mv selenium/ site/test/
git commit -m "Move selenium into the site"

# Generate the list of paths that we want to save from the version history
# to_keep.txt generated with find . -type f and then excluding things that we don't want
pushd site
cp .opensource_include /tmp/valid_sources.txt
find . -type f | grep -vf .opensource_exclude >> /tmp/valid_sources.txt
echo Calculating all historical paths for valid files
cat /tmp/valid_sources.txt | xargs -P 4 -n 1 git log --pretty=oneline --follow --name-only | grep -v ' ' | sort -u > /tmp/paths_to_keep.txt
popd

# Remove all copies of non desired files from the history
git filter-branch $GIT_TEMP --prune-empty -f --tag-name-filter cat --index-filter 'git ls-tree --name-only --full-tree $GIT_COMMIT | grep -vf /tmp/paths_to_keep.txt | xargs git rm -qrf --cached --ignore-unmatch' HEAD

exit 0
# Reroot the site dir at root
git filter-branch $GIT_TEMP --prune-empty -f --tag-name-filter cat --subdirectory-filter site HEAD

exit 0

# Garbage collect old revisions and versions now that we've deleted content
git reset --hard
rm -rf .git/refs/original/
git reflog expire --all --expire=now
git gc --aggressive --prune=now

exit 0

echo 'TODO: Ensure all versions are explicit in Gemfile'
echo 'TODO: Merge the selenium gemfiles into root'

# Add base engine files
cat > console.spec <<CONSOLE_SPEC
# encoding: utf-8
require File.expand_path('../lib/console/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors = ["Clayton Coleman"]
  gem.description = %q{The OpenShift application console is a Rails engine that provides an easy-to-use interface for managing your OpenShift applications.}
  gem.email = ['smarterclayton@gmail.com']
  gem.files = Dir['Gemfile', 'LICENSE.md', 'README.md', 'Rakefile', 'app/**/*', 'config/**/*', 'lib/**/*', 'public/**/*']
  gem.homepage = 'https://github.com/openshift/console'
  gem.name = 'console'
  gem.require_paths = ['lib']
  #gem.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')
  gem.summary = %q{Openshift Application Console}
  gem.test_files = Dir['test/**/*']
  gem.version = Console::VERSION
end
CONSOLE_SPEC

cat > lib/console.rb <<CONSOLE_RB
require 'console/engine.rb'
require 'console/version.rb'
module Console
end
CONSOLE_RB

mkdir lib/console/

cat > lib/console/engine.rb <<ENGINE_RB
require 'rails/engine'

module Console
  class Engine < Rails::Engine
end
ENGINE_RB

cat > lib/console/version.rb <<VERSION_RB
module Console
  VERSION = 1.0.0
end
VERSION_RB

git add .
git commit -m 'Create stub engine files'
