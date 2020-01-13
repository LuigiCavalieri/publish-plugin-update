#!/bin/bash
#
# This script automates some of the tasks needed for the publishing of
# plugin updates on WordPress.org.
#
# Version: 1.0
#
#
# Copyright 2019 Luigi Cavalieri.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# *********************************************************************** #

uglify() {
	file_type=$1
	filenames=$( find . -name "*.${file_type}" )

	if [ -z "${filenames}" ]; then
		return
	fi

	command_name="uglify${file_type}"

	if ! [ -x "$( command -v ${command_name} )" ]; then
		file_type_upper=$( echo "${file_type}" | tr '[:lower:]' '[:upper:]' )

		echo "Warning: ${file_type_upper} files cannot be compressed because '${command_name}' is not installed."
		
		read -p 'Do you wish to continue? (Y/N) ' answer

		if [ "${answer}" = 'Y' ] || [ "${answer}" = 'y' ]; then
			return
		fi
		
		exit
	fi

	for filename in $filenames; do
		if [[ "${filename}" =~ -min\.(css|js)$ ]]; then
		    continue
		fi
		
		extensionless_filename=${filename%.*}

		if [ "${file_type}" = 'css' ]; then
			uglifycss --debug --output "${extensionless_filename}-min.css" "${filename}"
		else
			uglifyjs "${filename}" --comments --compress --mangle --verbose --output "${extensionless_filename}-min.js"
		fi
	done
}

# *********************************************************************** #

plugin_version=""
plugin_folder_name=$1

while read line; do
	if [[ "${line}" =~ \"(.+)\":[[:blank:]]\"(.+)\" ]]; then
		constant_name=$( echo "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]' )

		readonly "${constant_name}"=${BASH_REMATCH[2]}
	fi
done < config.json

while [ -z "${plugin_folder_name}" ]; do
	read -p "Please, provide the name of the plugin's folder: " plugin_folder_name
done

cd "${WP_CONTENT_PATH}/plugins"

if ! [ -d "./${plugin_folder_name}" ]; then
	echo "Folder '${plugin_folder_name}' not found."
	exit
fi

cd "./${plugin_folder_name}"

while read line; do
	if [[ "${line}" =~ Version:[[:blank:]]*([.0-9]+) ]]; then
		plugin_version=${BASH_REMATCH[1]}
		break;
	fi
done < ${plugin_folder_name}.php

if [ -z "${plugin_version}" ]; then
	echo "Error: version number not found in '${plugin_folder_name}.php'."
	exit
fi

stable_tag_line=$( egrep --only-matching "Stable tag: *${plugin_version}" readme.txt )

if [ -z "${stable_tag_line}" ]; then
	echo "Warning: the 'Stable tag' value in the 'readme.txt' file has not been updated."

	read -p 'Do I have to update it for you? (Y/N) ' answer

	if [ "${answer}" != 'Y' ] && [ "${answer}" != 'y' ]; then
		echo 'Quit.'
		exit
	fi

	sed -i "" -E "s/Stable tag: *[.0-9]+/Stable tag: ${plugin_version}/" readme.txt
fi

WORKING_COPY_PATH="${SVN_ARCHIVE_PATH}/${plugin_folder_name}"

if [ -d "${WORKING_COPY_PATH}/tags/${plugin_version}" ]; then
	echo "Version ${plugin_version} has already been published."
	exit
fi

# If you don't want to compress CSS and JavaScript files
# or 'uglifycss' and 'uglifyjs' are not installed on your Mac
# you can comment the following two lines of code.
uglify 'css'
uglify 'js'

rsync --archive --delete --verbose --exclude='.DS_Store' --exclude='.git' . "${WORKING_COPY_PATH}/trunk"

cd $WORKING_COPY_PATH

repo_status=$( svn status )

if [ -z "${repo_status}" ]; then
	echo 'No changes to commit.'
	exit
fi

changes=( $repo_status )

for (( i=0; i<${#changes[@]}; i++ )); do
	case ${changes[i]} in
		'?') svn add "${changes[++i]}" ;;
		'!') svn delete "${changes[++i]}" ;;
		  *) (( i=i+1 )) ;;
	esac
done

svn copy trunk "tags/${plugin_version}"
svn commit -m "Publishing version ${plugin_version}."

echo "Version ${plugin_version} has been published on WordPress.org."