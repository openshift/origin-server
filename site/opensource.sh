if [ -d "../console" ]; then
  echo The directory ../console already exists.  To run you must 'rm -rf ../console'
  exit 1
fi
if [ -d "../console_clean" ]; then
  echo The directory ../console_clean already exists.  To run you must 'rm -rf ../console_clean'
  exit 1
fi

# run from the the li/ dir
pushd ..

# Use a simpler time format for values
export TIMEFORMAT=$'  Completed in %Rs\n'

# Create a utility script to remove empty branch parents
cat > /tmp/filter_empty_branch.rb <<FILTER_EMPTY_BRANCH_RB
#!/usr/bin/ruby
old_parents = gets.chomp.gsub('-p ', ' ')

if old_parents.empty? then
  new_parents = []
else
  new_parents = %x[git show-branch --independent #{old_parents}].split
end

puts new_parents.map{|p| '-p ' + p}.join(' ')
FILTER_EMPTY_BRANCH_RB
chmod 770 /tmp/filter_empty_branch.rb

# Initial working repository setup
git clone --no-hardlinks li console
pushd console/
git checkout master

# Preserve selenium
git mv selenium/Gemfile site/test/Gemfile_old
git mv selenium/Gemfile.lock site/test/Gemfile_old.lock
git mv selenium/ site/test/
git commit -m "Move selenium into the site"

# Make any other repository changes here

# Generate the list of paths that we want to save from the version history
# to_keep.txt generated with find . -type f and then excluding things that we don't want
pushd site
cp .opensource_include /tmp/valid_sources.txt
find . -type f | grep -vf .opensource_exclude | sort -u >> /tmp/valid_sources.txt

echo Generating script to separate content that went into the new repository
find . | grep -f /tmp/valid_sources.txt | sort -u | xargs -n 1 echo git rm > /tmp/delete_moved.sh
chmod 770 /tmp/delete_moved.sh
echo '  Run /tmp/delete_moved.sh from the li/site dir to remove all content that was copied into the new repository.'

echo Calculating all historical paths for valid files
time cat /tmp/valid_sources.txt | xargs -P 4 -n 1 git log --pretty=oneline --follow --name-only | grep -v ' ' | sort -u > /tmp/paths_to_keep.txt
popd

echo "Found `cat /tmp/valid_sources.txt | wc -l` files to preserve in the version history (cat /tmp/valid_sources.txt for the complete list)."
while true; do
  read -p "Ready to begin rewritting git history - this process may take up to an hour.  Continue? (y/n) " yn
  case $yn in
    [Yy]* ) break;;
    [Nn]* ) exit 1;;
    * ) echo "Please answer y or n.";;
  esac
done

echo Remove unecessary branches and tags
# remove unnecessary branches
git branch -a | egrep -v "master|origin/master|origin/HEAD" |
  while read branch; do
    git branch -r -d "${branch/remotes\//}"
  done

# remove unnecessary tags
time git tag -l | grep -vE "^0\.|rhc-0|rhc-site-0" | while read tag; do git tag -d "${tag}"; done


echo Rewriting git history to contain only paths listed in /tmp/paths_to_keep.txt

# Remove all copies of non desired files from the history
time git filter-branch $GIT_TEMP --prune-empty -f --tag-name-filter cat --index-filter 'git ls-tree -r --name-only --full-tree $GIT_COMMIT | grep -vf /tmp/paths_to_keep.txt | xargs git rm -qrf --cached --ignore-unmatch' -- --all

echo Removing empty branches and merge commits
time git filter-branch $GIT_TEMP --prune-empty -f --tag-filter-name cat --parent-filter /tmp/filter_empty_branch.rb -- --all

echo Rewriting git history to move all /site content to /

# Reroot the site dir at root
echo To reroot /site to / (as last final step)
echo time git filter-branch $GIT_TEMP --prune-empty -f --tag-name-filter cat --subdirectory-filter site -- --all

popd
git clone --no-hardlinks console console_clean
pushd console_clean

# Garbage collect old revisions and versions now that we've deleted content
git reset --hard
rm -rf .git/refs/original/
git reflog expire --all --expire=now
git gc --aggressive --prune=now

echo Total size of repository: `du -sh`
echo Git rewrite complete, repository contains only the desired history
echo ----------------------------------
echo 'TODO: Ensure all versions are explicit in Gemfile'
echo 'TODO: Merge the selenium gemfiles into root'
echo 'TODO: Reintroduce web_user and add base helpers'

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
