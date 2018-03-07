-- Settings
global configFile
set configFile to "~/.pr-repos.plist"

global debugCommand
set debugCommand to false

global confirmationTimeout
set confirmationTimeout to 5

-- Standard error codes
-- See: https://developer.apple.com/library/content/documentation/AppleScript/Conceptual/AppleScriptLangGuide/reference/ASLR_error_codes.html
global codeObjectDoesNotExist
set codeObjectDoesNotExist to -1728

-- Given a path, expand ~ into the user's home directory
on normalizePath(p)
	return do shell script "p=\"" & p & "\"; echo \"${p/#~/$HOME}\""
end normalizePath

-- Concatenates two paths
on pathConcat(p1, p2)
	if p1 ends with "/" then
		return p1 & p2
	else
		return p1 & "/" & p2
	end if
end pathConcat

-- Returns the string value of the given key within the config file, if present
on getConfigKey(key)
	tell application "System Events"
		try
			tell application "System Events"
				if exists file configFile then
					tell property list file configFile
						if kind of property list item key = string then
							return value of property list item key
						else
							-- Item has a non-string value
							return ""
						end if
					end tell
				else
					-- Config file does not exist
					return ""
				end if
			end tell
		on error message number code
			if code = codeObjectDoesNotExist then
				-- Either config the file format is bad, or the key was not found
				return ""
			else
				display dialog "Unexpected error!

" & message & "

code: " & code buttons {"OK"} default button "OK" cancel button "OK"
			end if
		end try
	end tell
end getConfigKey

-- Given a github username and repo name, determine the local path to the repo
on getRepoLocation(user, repo)
	-- Look for a specific directory for this user and repo
	set location to getConfigKey(user & "/" & repo)
	if location = "" then
		-- Look for a specific directory for any repo with the same name
		set location to getConfigKey(repo)
	end if
	
	-- Return if we found a specific directory
	if not location = "" then
		return normalizePath(location)
	end if
	
	-- Look for a base directory for this user
	set location to getConfigKey(user & "/*")
	if location = "" then
		-- Look for a global base directory
		set location to getConfigKey("*")
	end if
	
	-- Return if we found a base directory
	if not location = "" then
		return pathConcat(normalizePath(location), repo)
	end if
	
	-- Repo location could not be determined
	display dialog "Could not determine repo location.

user: " & user & "
repo: " & repo buttons {"OK"} default button "OK" cancel button "OK"
end getRepoLocation

-- This handler is invoked for URLs using our custom protocol prefix
on open location thisUrl
	-- Parse the user, repo, and branch names from the URL
	set AppleScript's text item delimiters to "/"
	set parts to every text item of thisUrl
	if 5 is greater than (count of parts) then
		display dialog "Invalid PR URL: " & thisUrl
	else
		set user to item 3 of parts
		set repo to item 4 of parts
		set branch to item 5 of parts
		if 5 is less than (count of parts) then
			repeat with i from 6 to count of parts
				set branch to branch & "/" & item i of parts
			end repeat
		end if
	end if
	
	-- Determine the repo location
	set location to getRepoLocation(user, repo)
	
	-- Inform the user of what we're about to do
	display dialog "Launching difftool in " & confirmationTimeout & " seconds ...
	
user: " & user & "
repo: " & repo & "
branch: " & branch & "
location: " & location giving up after confirmationTimeout
	
	-- Build the git difftool command
	set command to "source ~/.bashrc;"
	set command to command & "export PATH=$PATH:/usr/local/bin;"
	set command to command & "cd \"" & location & "\";"
	set command to command & "git difftool --dir-diff --no-symlink \"master...origin/" & branch & "\";"
	if debugCommand then
		display dialog "Running command:

" & command
	end if
	
	-- Run the command and display any errors to the user
	try
		do shell script command
	on error message number code
		display dialog "Command failed!

" & message & "

code: " & code buttons {"OK"} default button "OK" cancel button "OK"
	end try
	
end open location

-- Display usage info if this app is invoked directly
display dialog "GitHub Pull Request Diff Viewer

To use this app, open a URL in the following format:

prdiff://<user or org>/<repo>/<PR branch>" buttons {"OK"} default button "OK"