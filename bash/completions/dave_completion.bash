#!/bin/bash

# Function for completing categories (subfolders)
_dave_categories() {
  local dir="$HOME/.bin/dave-scripts"
  COMPREPLY=($(compgen -d -- "${dir}/" | sed "s|${dir}/||"))
}

# Function for completing commands (scripts within categories)
_dave_commands() {
  local category="${COMP_WORDS[1]}"
  local dir="$HOME/.bin/dave-scripts/$category"

  # Get the list of scripts in the category
  local matches=($(compgen -f -- "${dir}/"))

  # If there's only one match, complete it automatically with the relative path
  if [ ${#matches[@]} -eq 1 ]; then
    COMPREPLY=("${matches[0]#$dir/}")
  else
    COMPREPLY=($(compgen -f -- "${dir}/" | sed "s|${dir}/||"))
  fi
}

# Register the completion function for dave command
complete -F _dave_categories dave
complete -F _dave_commands dave


# PROMPT:
#So I have made a bash script named "dave". When I type "dave rails migrate" it will look in ~/.bin/dave-scripts/rails to execute a script called "migrate". Any arguments following "dave rails migrate" will be passed along to the migrate script.

#I now want to have bash autocompletion for the "dave" command. It should complete two things:

#1. The subfolders in ~/.bin/dave-scripts.
#2. The scripts in each subfolder. 

#Now Assume for the rest of this script that the following files exist:
#~/.bin/dave-scripts/rails/migrate
#~/.bin/dave-scripts/rails/migod
#~/.bin/dave-scripts/rails/bootstrap
#~/.bin/dave-scripts/mysql/drop-tables

#The behaviour of the bash completion should be as follows:
#1. When I type "dave " followed by <TAB> it should cycle inline completion for each of the subfolders
#2. When I type "dave ra" followed by <TAB> it should cycle inline completion only for the subfolders the being with "ra". If no matches are found, it does not complete anything.
#3. When I type "dave r" followed by <TAB> and there is only 1 match that begins with an "r", it should autocomplete to the only match.

#Assuming I make it past the subfolder and I can complete to "dave rails ", I expect the following behaviour:
#1. When I immediately press <TAB> again, it should cycle inline completion for each of the scripts within ~/.bin/dave-scripts/rails/.
#2. When I add "foo" to the prompt followed by <TAB>, it should not complete anything because no script starting with that name exists.
#3. When I add "m" to the prompt and press <TAB>, it should cycle between both "migrate" and "migod" because both start with an "m".
#4. When I add "b" to the prompt followed by <TAB>, it should autocomplete to "bootstrap" because that's the only script in the subfolder starting with "b".
