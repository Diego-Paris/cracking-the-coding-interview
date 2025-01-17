#! /usr/bin/env sh
# This basic file was cribbed liberally from the post at
# https://codeinthehole.com/tips/tips-for-using-a-git-pre-commit-hook/
# but the Git commands have been updated for current best practices.

# Sanity checker. Alerts to STDOUT that the pre-commit hook is about to run.
# (uncomment to use)
# echo "Running the pre-commit hook..."

# Stash any unstaged changes so that they don't interefere with the test suite
# We only want tests to run on the code that has been staged for commit, and not
# other unstaged files in the working directory.

# Uniquely name the stash with a Unix timestamp.
STASH_NAME="pre-commit-$(date +%s)"

# Use the preferred `git stash push` command; see
# https://git-scm.com/docs/git-stash#_commands. Preserve the index (things
# already staged with `git add`) and include any untracked files in the stash.
git stash push -q --keep-index --include-untracked --message $STASH_NAME

# Track and increment the number of failed tests
FAILED_TESTS=0
trap 'FAILED_TESTS=$((FAILED_TESTS+1))' ERR
# List all test commands to be run
make test

# Restore the repository to its pre-test state.
# Look through the list of stashes for the matching stash:
STASHES=$(git stash list -1 | grep -o $STASH_NAME)
# Once a match is found with the correct stash, restore the repo by applying it:
if [[ $STASHES == $STASH_NAME ]]; then
  # echo "Restoring stashed changes..."
  # Reset the repository completely (useful when tests generate or modify any
  # files, although such files should probably be in a `.gitignore` file
  # anyway), apply the stash and the restore the index. Quietly drop the stash
  # once applied (-q).
  git reset --hard -q && git stash apply --index -q && git stash drop -q
fi

# If the number of failed tests isn't zero, exit with status 1 and halt the
# commit.
if ((FAILED_TESTS == 0)); then
  exit 0 # Proceed with the commit
else
  echo "Unable to make commit; fix code and stage fixes with \`git add\`"
  exit 1 # Halt the commit
fi