## this chatgpt script is probably not needed anymore
## but I'm gonna keep it around for now
@tool
extends EditorScript

func _run():
    print("Starting scan for custom resources...")
    var files := _scan_files("res://")
    var fixed_count := 0
    var skipped_count := 0

    for f in files:
        if not f.ends_with(".tres"):
            continue

        # Read file as plain text
        var file = FileAccess.open(f, FileAccess.READ)
        if not file:
            continue
        var lines := file.get_as_text().split("\n")
        file.close()
        if lines.size() == 0:
            continue

        var header := lines[0]

        # Only modify headers that are plain Resource with a script_class
        if header.begins_with("[gd_resource type=\"Resource\"") and header.find("script_class=") != -1:
            var regex := RegEx.new()
            regex.compile("script_class=\"([A-Za-z0-9_]+)\"")
            var res := regex.search(header)
            if res:
                var custom_type := res.get_string(1)
                print("Fixing:", f, " →", custom_type)

                # Rewrite the header
                header = header.replace("type=\"Resource\"", "type=\"%s\"" % custom_type)
                header = header.replace("script_class=\"%s\"" % custom_type, "")
                lines[0] = header

                # Save back
                file = FileAccess.open(f, FileAccess.WRITE)
                if file:
                    file.store_string("\n".join(lines))
                    file.close()
                    fixed_count += 1
            else:
                skipped_count += 1
        else:
            skipped_count += 1

    print("Scan complete. Fixed %d files, skipped %d" % [fixed_count, skipped_count])


# Recursive file scan
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
