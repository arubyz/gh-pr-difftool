# Description

A combination of a Chrome extension and a MacOS AppleScript application which together enable launching of an external diff client directly from a GitHub PR page.

# Build

* `cd app; make`
* Output is `out/PRDiff.app`

# Installation

* `git clone` this repository and build.

* Install the extension in Chrome.

* Using Finder, move `PRDiff.app` to another folder (after that you may move it back to its original location if you wish).  Then launch `PRDiff.app` and dismiss the dialog box that appears.  These steps should help ensure that `PRDiff.app` is registered to handle URLs with protocol `prdiff://`.

  * To test the protocol registration, enter the following in a terminal:

    ```shell
    open prdiff://user/repo/branch
    ```

# Usage

* Register a diff client to use as your `git difftool`.  For example, to use Beyond Compare enter the following in a terminal:

  ```shell
  git config --global diff.tool bc3
  ```

* Create a new XML plist file at `~/.pr-repos.plist`.  Each plist item should be of one of the following types.  When looking up a specific *user* and *repo*, items of each type are consulted in the following order:

  * An item with the name "*user*/*repo*".  The value is the exact directory for the repo.
  * An item with the name "*repo*".  The value is the exact directory for any repo with that name.
  * An item with the name "*user*/*".  The value is the base directory for any repo under that user.
  * An item with the name "*".  The value is the base directory for any repo.

* Navigate to a PR on github.com and then press the browser extension icon labeled "Launch 'diff tool'".  A dialog will comfirm the repo and branch details before launching your registered diff client.

# Notes

* If the diff client does not appear to launch, it is probably because the PR has been merged to master and thus there is no diff to show.  `git difftool` is documented to work that way in this case.  To debug further, set `debugCommand` to true inside the app's AppleScript source and manually run the git command it displays.
* The invocation of `git difftool` will not indicate whether there would be any conflicts merging the PR into master.  This should be checkedf on the GitHub PR page first.

# Internals

* Whem the extension button is pressed, a content script is injected into the current page.
* The content script extracts the branch name from the web page content, and the user and repo name from the URL.  All three pieces of data are passed back the the extension in a message.
* The extension has the browser open a URL with the `prdiff://` protocol, containing the user, repo, and branch of the PR.
* `PRDiff.app` is invoked to handle the `prdiff://` protocol URL.
* The app finds the local directory of the repo according to the rules in `~/.pr-repos.plist` and uses a shell script to invoke `git difftool`.
  * The `—dir-diff` option invokes the diff tool once for all files.
  * The `—no-symlinks` creates real file copies to diff rather than symlinks.
  * The diff range is specified as "master...origin/*branch*".  This uses the same mechanism as `git merge-base` to find the most recent merge from master into the PR branch.  Diffing the PR branch head with the merge base is a close approximation of the actual result of merging the PR.
