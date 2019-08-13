#!/bin/bash

#### Package: macup/macup-dotfiles-cloud
#### Description: macup module that keeps your dotfiles in sync through cloud drive
function copy_to_cloud {
  local file=$1
  local path_to_dotfiles
  path_to_dotfiles=$(get_path_to_dotfiles)
  local path_to_file
  path_to_file=$(dirname $file)

  if [ -f "$HOME/$file" ]; then
    report_from_package "Copying local file to cloud, since it doesn't exist in cloud yet"
    cp "$HOME/$file" "$path_to_dotfiles/$file"
  else
    report_from_package "The file $file needs to be added to cloud!" "yellow"
  fi
}

function get_path_to_dotfiles {
  if [ "$macup_dotfiles_cloud_type" = "dropbox" ]; then
    echo "$HOME"/Dropbox/.dotfiles
  elif [ "$macup_dotfiles_cloud_type" = "icloud" ]; then
    echo "$HOME"/Library/Mobile\ Documents/com~apple~CloudDocs/.dotfiles
  else
    echo "$HOME"/Library/Mobile\ Documents/com~apple~CloudDocs/.dotfiles
  fi
}

function hardlink_dotfile {
  local file=$1
  local chmod=$2
  local num_links=0
  local path_to_dotfiles
  path_to_dotfiles=$(get_path_to_dotfiles)
  local path_to_file
  path_to_file=$(dirname $file)

  # Create dirs locally if neccesary
  if [ ! -d "$HOME"/"$path_to_file" ]; then
    report_from_package " the directory $path_to_file doesn't exist locally. Creating"
    mkdir -p "$HOME"/"$path_to_file"

    # Ensure .ssh dir is chmod'ed correctly
    if [ "$path_to_file" == ".ssh" ]; then
      chmod 700 "$path_to_file"
    fi
  fi
  
  # Detect if the file is a hard link
  if [ -f "$HOME"/"$file" ]; then
    num_links=$(stat -f "%l" "$HOME/$file")
  fi

  # If the file doesn't exist as hard link in your system, we'll create a hard link to cloud
  if [ "$num_links" != "2" ]; then

    # shellcheck disable=SC2088
    report_from_package "~/$file doesn't exist as hard link locally. Will create a hard link to cloud"

    if [ -f "$HOME"/"$file" ]; then
      report_from_package "Removing static file $file"
      rm "$HOME"/"$file"
    fi

    if [ -f "$path_to_dotfiles"/"$file" ]; then
      ln "$path_to_dotfiles"/"$file" "$HOME"/"$file"
    else
      report_from_package "WARN: $file doesn't exist in cloud. Skipping" 'yellow'
    fi
  else
    if [ ! -f "$path_to_dotfiles"/"$file" ]; then
      report_from_package "WARN: $file doesn't exist in cloud. Removing" 'yellow'
      unlink "$HOME"/"$file"
    fi

    # shellcheck disable=SC2088
    report_from_package "~/$file is already hard linked to cloud"
  fi
  
  if [ -n "$chmod" ] && [ "$chmod" -eq "$chmod" ] 2>/dev/null; then
    if [ -L "$HOME"/"$file" ]; then
      report_from_package " chmod -h $chmod $HOME/$file"
      chmod "$chmod" "$HOME"/"$file"
    elif [ -f "$HOME"/"$file" ]; then
      report_from_package " chmod $chmod $HOME/$file"
      chmod "$chmod" "$HOME"/"$file"
    fi
  fi
}

if [ ! -L .dotfiles-in-cloud ]; then
  # Check if .dotfiles exist in cloud drive
  if [ ! -d "$(get_path_to_dotfiles)" ]; then
    report_from_package "Creating .dotfiles directory in cloud drive"
    mkdir "$(get_path_to_dotfiles)"
  else
    report_from_package ".dotfiles directory already exist in cloud drive"
  fi

  report_from_package "Creating a local symlink to the cloud dotfiles folder (.dotfiles-in-cloud)"
  ln -s "$(get_path_to_dotfiles)" .dotfiles-in-cloud
fi

# todo: check if array is declared up front!
# shellcheck disable=SC2154
if [ ${#macup_dotfiles_cloud_files[@]} -eq 0 ]; then
  report_from_package "No dotfiles to install. Addd files to the \$macup_dotfiles_cloud_files array" "yellow"
fi

for ((i=0; i<${#macup_dotfiles_cloud_files[@]}; ++i)); do
  file="$(echo "${macup_dotfiles_cloud_files[i]}" | cut -d':' -f1)"
  chmod="$(echo "${macup_dotfiles_cloud_files[i]}" | cut -d':' -f2)"

  if [ ! -f "$(get_path_to_dotfiles)"/"$file" ]; then
    copy_to_cloud "$file"
  fi
  
  hardlink_dotfile "$file" "$chmod"
done
