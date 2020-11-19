# publish-plugin-update.sh

A bash script to automate some of the tasks needed for the publishing of plugin updates on WordPress.org.


## What it Does

In chronological order, the following are all the tasks the script goes through:

1. Checks whether or not the 'Stable tag' value in the `readme.txt` file matches the 'Version' value found in the `plugin-name.php` file.
2. Verifies that the current version of the plugin hasn't already been tagged, and so, published.
3. If the plugin contains CSS or JavaScript files and you have [uglifycss](https://www.npmjs.com/package/uglifycss) and [uglifyjs](https://www.npmjs.com/package/uglify-js) installed on your Mac, it adds a compressed version of these files in the same folder as the original version. The compressed version will have a `-min` suffix in the filename.
4. Synchronises the 'trunk' folder of the Working Copy with the plugin's folder, by leaving out the `.DS_Store` files and the `.git` folder that might be present.
5. If needed, runs `svn add` and `svn delete` on the paths of the files respectively added to or deleted from the 'trunk' folder.
6. Makes a SVN copy of the 'trunk' folder to the `tags/current_version` subdirectory of the Working Copy.
7. And finally publishes the update on WordPress.org by committing the changes made to the Working Copy of the SVN repository.


## Usage

The script needs a preliminary configuration through the file `config.json`.

Once configured, you can launch it like so:

```
$ path-to/publish-plugin-update.sh plugin-folder-name
```


## Licence

Licenced under the [GPL v3.0](https://opensource.org/licenses/GPL-3.0).


## Notes

Developed on macOS 10.15.7 with GNU bash 3.2.57.