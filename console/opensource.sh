# Use a simpler time format for values
export TIMEFORMAT=$'  Completed in %Rs\n'
export DIR=foo
export REPO=test_git2
export REPO_WORKING=${REPO}_working
export REPO_CLEAN=${REPO}_clean

exit

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
git clone --no-hardlinks $REPO $REPO_WORKING
pushd $REPO_WORKING/
git checkout master

# Preserve selenium
#git mv selenium/Gemfile site/test/Gemfile_old
#git mv selenium/Gemfile.lock site/test/Gemfile_old.lock
#git mv selenium/ site/test/
#git commit -m "Move selenium into the site"

# Make any other repository changes here

# Generate the list of paths that we want to save from the version history
# to_keep.txt generated with find . -type f and then excluding things that we don't want
pushd $DIR
cp .opensource_include /tmp/valid_sources.txt
find . -type f | grep -vf .opensource_exclude | sort -u >> /tmp/valid_sources.txt

echo Generating script to separate content that went into the new repository
find . | grep -f /tmp/valid_sources.txt | sort -u | xargs -n 1 echo git rm > /tmp/delete_moved.sh
chmod 770 /tmp/delete_moved.sh
echo '  Run /tmp/delete_moved.sh from the li/$DIR dir to remove all content that was copied into the new repository.'

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

# remove all tags
time git tag -l | while read tag; do git tag -d "${tag}"; done

echo Rewriting git history to contain only paths listed in /tmp/paths_to_keep.txt

# Remove all copies of non desired files from the history
time git filter-branch $GIT_TEMP --prune-empty -f --tag-name-filter cat --index-filter 'git ls-tree -r --name-only --full-tree $GIT_COMMIT | grep -vf /tmp/paths_to_keep.txt | xargs -r git rm -qrf --cached --ignore-unmatch' -- --all

echo Removing empty branches and merge commits
time git filter-branch $GIT_TEMP --prune-empty -f --tag-filter-name cat --parent-filter /tmp/filter_empty_branch.rb -- --all

echo Rewriting git history to move all /$DIR content to /
time git filter-branch $GIT_TEMP --prune-empty -f --subdirectory-filter $DIR -- --all

# Reroot the site dir at root
echo 'To reroot /$DIR to / (as last final step)'
echo 'time git filter-branch $GIT_TEMP --prune-empty -f --tag-name-filter cat --subdirectory-filter $DIR -- --all'

popd
git clone --no-hardlinks $REPO_WORKING $REPO_CLEAN
pushd $REPO_CLEAN/

# Garbage collect old revisions and versions now that we've deleted content
git reset --hard
rm -rf .git/refs/original/
git reflog expire --all --expire=now
git gc --aggressive --prune=now

echo Total size of repository: `du -sh`
echo Git rewrite complete, repository contains only the desired history
echo ----------------------------------

echo To merge this
echo $ git remote add -f CONSOLE /path/to/li
echo $ git merge -s ours --no-commit CONSOLE/master
echo $ git read-tree --prefix=console/ -u CONSOLE/master
echo $ git commit
