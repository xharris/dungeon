@tool
extends EditorScript

## This script scans all .tres files.
## If the file header looks like:
##   [gd_resource type="Resource" script_class="MyClass"]
## …it will rewrite it to:
##   [gd_resource type="MyClass"]
##
## Works for any custom class registered with `class_name`.

func _run():
    var files := _scan_files("res://")
    var fixed_count := 0
    var skipped_count := 0
    
    for f in files:
        if not f.ends_with(".tres"):
            continue

        var content := FileAccess.get_file_as_string(f)
        if content.is_empty():
            continue
        
        var lines := content.split("\n")
        var header := lines[0]
        
        # Look for "Resource" base with script_class
        if header.begins_with("[gd_resource type=\"Resource\"") and header.find("script_class=") != -1:
            # Extract the script_class
            var match := header.find("script_class=")
            if match != -1:
                var regex := RegEx.new()
                regex.compile("script_class=\"([A-Za-z0-9_]+)\"")
                var res := regex.search(header)
                if res:
                    var custom_type := res.get_string(1)
                    print("Fixing:", f, " →", custom_type)
                    
                    # Replace type
                    header = header.replace("type=\"Resource\"", "type=\"%s\"" % custom_type)
                    # Strip script_class
                    header = header.replace("script_class=\"%s\"" % custom_type, "")
                    lines[0] = header
                    
                    # Save back
                    var file = FileAccess.open(f, FileAccess.WRITE)
                    file.store_string("\n".join(lines))
                    file.close()
                    
                    fixed_count += 1
                    continue
        
        skipped_count += 1
    
    print("Scan complete. Fixed %d files, skipped %d" % [fixed_count, skipped_count])


func _scan_files(path: String) -> Array[String]:
    var results: Array[String] = []
    var dir = DirAccess.open(path)
    if not dir:
        return results
    
    dir.list_dir_begin()
    var fname = dir.get_next()
    while fname != "":
        if fname == "." or fname == "..":
            fname = dir.get_next()
            continue

        var fpath = path.path_join(fname)
        if dir.current_is_dir():
            results.append_array(_scan_files(fpath))
        else:
            results.append(fpath)
        fname = dir.get_next()
    dir.list_dir_end()
    return results
