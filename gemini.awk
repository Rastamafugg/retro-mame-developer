#!/usr/bin/awk -f

# AWK Transpiler for Enhanced Basic09 to standard Basic09
#
# USAGE:
#   awk -f this_script.awk global.b09 module_source.b09
#
# DESCRIPTION:
# This script processes an enhanced Basic09 module file and a global
# definition file to produce standard, compilable Basic09 code. It operates
# in two main passes:
#
# Pass 1: Gathers all TYPE, CONST, VAR, and ENUM definitions, as well as
#         GOTO/GOSUB labels. It respects global, module, and procedure scopes.
#
# Pass 2: Processes the source code line-by-line to perform transformations.
#         A state machine ensures ONLY code inside PROCEDURE blocks is
#         processed and printed to the final output.
#         - Replaces @@TOKEN statements with their full definitions.
#         - Translates CONST and VAR into DIM statements.
#         - Converts ENUM blocks into individual variable declarations.
#         - Substitutes constant values within DIM array declarations.
#         - Transforms SELECT CASE blocks into IF/ELSE IF structures.
#         - Replaces GOTO/GOSUB labels with auto-generated line numbers.

# ==============================================================================
# === PASS 1: Read all files, collect definitions and labels                 ===
# ==============================================================================
BEGIN {
    # State variables
    current_scope = "none"
    line_number_counter = 100
}

# This block executes for every line of every input file
{
    # Determine current file and scope (global vs. module)
    if (FNR==1) {
        current_filename = FILENAME
        if (FILENAME ~ /global\.b09$/) {
            current_scope = "global"
        } else {
            # Reset module-specific definitions for the new file
            current_scope = "module_header"
            delete module_types; delete module_consts; delete module_vars; delete module_const_vals
        }
    }

    # Store all lines of the main module file for Pass 2 processing
    if (current_filename !~ /global\.b09$/) {
        lines[FNR] = $0
    }

    # --- Definition and Label Parsing ---

    # Update scope based on MODULE/PROCEDURE keywords
    if (current_filename !~ /global\.b09$/) {
        if ($1 == "MODULE")   { current_scope = "module_header" }
        if ($1 == "PROCEDURE") {
            current_scope = $2 # Scope is now the procedure name
            # Clear any definitions from a previous procedure with the same name
            delete proc_types[current_scope]; delete proc_consts[current_scope]
            delete proc_vars[current_scope]; delete proc_const_vals[current_scope]
            delete enums[current_scope]; delete enum_defs[current_scope]
        }
    }
    
    # Parse TYPE definition
    if (match($0, /^[[:space:]]*TYPE[[:space:]]+([a-zA-Z0-9_]+)/, m)) {
        if (current_scope == "global")        global_types[m[1]] = $0
        else if (current_scope == "module_header") module_types[m[1]] = $0
        else                                  proc_types[current_scope][m[1]] = $0
    }

    # Parse CONST definition
    if (match($0, /^[[:space:]]*CONST[[:space:]]+([a-zA-Z0-9_$]+)[[:space:]]*:([^:=]+):=(.*)/, m)) {
        def_name = m[1]; def_type = m[2]; def_val = m[3]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", def_type)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", def_val)
        
        # Prepare the transpiled lines
        dim_line = "DIM " def_name ":" def_type
        assignment_line = def_name " := " def_val
        
        if (current_scope == "global") {
            global_consts[def_name] = dim_line "\n" assignment_line
            global_const_vals[def_name] = def_val
        } else if (current_scope == "module_header") {
            module_consts[def_name] = dim_line "\n" assignment_line
            module_const_vals[def_name] = def_val
        } else { # Procedure scope
            proc_consts[current_scope][def_name] = dim_line "\n" assignment_line
            proc_const_vals[current_scope][def_name] = def_val
        }
    }

    # Parse VAR definition
    if (match($0, /^[[:space:]]*VAR[[:space:]]+([a-zA-Z0-9_$]+):(.*)/, m)) {
        def_name = m[1]; def_type = m[2]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", def_type)
        full_line = "DIM " def_name ":" def_type
        
        if (current_scope == "global")        global_vars[def_name] = full_line
        else if (current_scope == "module_header") module_vars[def_name] = full_line
        else                                  proc_vars[current_scope][def_name] = full_line
    }

    # Parse ENUM definition (procedure scope only)
    if (current_scope != "global" && current_scope != "module_header") {
        if (match($0, /^[[:space:]]*ENUM[[:space:]]+([a-zA-Z0-9_]+)[[:space:]]*=[[:space:]]*\[(.*)\]/, m)) {
            enum_name = m[1]; enum_pairs_str = m[2]
            split(enum_pairs_str, pairs, ",")
            for (i in pairs) {
                split(pairs[i], pair, "=")
                member = pair[1]; value = pair[2]
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", member)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
                
                # Store for replacing "Enum.Member" with "Member"
                enums[current_scope][enum_name "." member] = member
                # Store the value for constant substitution
                proc_const_vals[current_scope][member] = value
                # Store the full transpiled definition lines
                enum_defs[current_scope][enum_name] = enum_defs[current_scope][enum_name] "DIM " member ":INTEGER\n" member " := " value "\n"
            }
        }
    }
    
    # Find GOTO/GOSUB label definitions (e.g., "ErrorHandler:")
    if (match($0, /^[[:space:]]*([a-zA-Z][a-zA-Z0-9_]*):[[:space:]]*(!.*)?$/)) {
        label_name = substr($0, RSTART, RLENGTH)
        gsub(/^[[:space:]]+|[[:space:]]*:.*$/, "", label_name)
        if (!(label_name in labels)) {
            labels[label_name] = line_number_counter
            line_number_counter += 100
        }
    }
}

# ==============================================================================
# === PASS 2: Process stored lines and print transpiled code                 ===
# ==============================================================================
END {
    # State variables for Pass 2 transformation
    in_procedure = ""
    in_select = 0
    select_indent = ""
    
    for (i = 1; i <= length(lines); i++) {
        line = lines[i]

        # --- State Machine: A procedure ends when the next one begins, or the module ends. ---
        is_proc_start = match(line, /^[[:space:]]*PROCEDURE[[:space:]]+([a-zA-Z0-9_]+)/, m)
        is_endmodule = match(line, /^[[:space:]]*ENDMODULE/)

        # If a new procedure or end of module is found, we are no longer "in" the previous procedure.
        if (is_proc_start || is_endmodule) {
            if (in_procedure != "") {
                # Add a blank line for readability between procedures
                print ""
            }
            in_procedure = ""
        }

        # If the current line starts a new procedure, enter the "in procedure" state.
        if (is_proc_start) {
            in_procedure = m[1]
        }
        
        # Gatekeeper: If we are not in a procedure, skip to the next line.
        if (in_procedure == "") {
            continue
        }

        # --- Line Processing: Only runs for lines inside a procedure ---

        # Pre-Transformation Substitutions
        # Substitute ENUM members (e.g., "Color.Red" -> "Red")
        if (in_procedure in enums) {
            for (enum_key in enums[in_procedure]) {
                gsub(enum_key, enums[in_procedure][enum_key], line)
            }
        }
        
        # Substitute CONST values in DIM array declarations (e.g., "DIM arr[MaxReadings]")
        if (line ~ /^[[:space:]]*DIM/) {
            if (in_procedure in proc_const_vals) {
                for (c in proc_const_vals[in_procedure]) gsub("\\[" c "\\]", "[" proc_const_vals[in_procedure][c] "]", line)
            }
            for (c in module_const_vals) { gsub("\\[" c "\\]", "[" module_const_vals[c] "]", line) }
            for (c in global_const_vals) { gsub("\\[" c "\\]", "[" global_const_vals[c] "]", line) }
        }

        # Preserve indentation for generated code
        match(line, /^([[:space:]]*)/); indent_str = substr(line, RSTART, RLENGTH)

        # --- Transformation Logic (as if/else if/else chain) ---

        # 1. @@TOKEN Replacement
        if (match(line, /^[[:space:]]*@@(TYPE|CONST|VAR)[[:space:]]+([a-zA-Z0-9_$]+)/, m)) {
            type = m[1]; name = m[2]; found = 0
            if (type == "TYPE") {
                if (in_procedure in proc_types && name in proc_types[in_procedure]) { print indent_str proc_types[in_procedure][name]; found=1 }
                else if (name in module_types) { print indent_str module_types[name]; found=1 }
                else if (name in global_types) { print indent_str global_types[name]; found=1 }
            } else if (type == "CONST") {
                def_string = ""
                if (in_procedure in proc_consts && name in proc_consts[in_procedure]) { def_string = proc_consts[in_procedure][name]; found=1 }
                else if (name in module_consts) { def_string = module_consts[name]; found=1 }
                else if (name in global_consts) { def_string = global_consts[name]; found=1 }

                if (found) {
                    split(def_string, lines_to_print, "\n")
                    for (line_idx in lines_to_print) {
                        print indent_str lines_to_print[line_idx]
                    }
                }
            } else if (type == "VAR") {
                if (in_procedure in proc_vars && name in proc_vars[in_procedure]) { print indent_str proc_vars[in_procedure][name]; found=1 }
                else if (name in module_vars) { print indent_str module_vars[name]; found=1 }
                else if (name in global_vars) { print indent_str global_vars[name]; found=1 }
            }
            if (!found) { print indent_str "REM ERROR: Definition not found for " name }
        
        # 2. ENUM Declaration Replacement
        } else if (match(line, /^[[:space:]]*ENUM[[:space:]]+([a-zA-Z0-9_]+)/, m)) {
            enum_name = m[1]
            if (in_procedure in enum_defs && enum_name in enum_defs[in_procedure]) {
                split(enum_defs[in_procedure][enum_name], defs, "\n")
                for (d in defs) if (defs[d] != "") print indent_str defs[d]
            }
        
        # 3. GOTO/GOSUB/Label Replacement
# 3. GOTO/GOSUB/Label Replacement
        } else if (match(line, /^[[:space:]]*ON[[:space:]]+.*(GOTO|GOSUB)[[:space:]]+([a-zA-Z0-9_,[:space:]]+)/, m)) {
            labels_str = m[2]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", labels_str)
            split(labels_str, label_arr, ","); new_list = ""
            for (l in label_arr) {
                lbl = label_arr[l]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", lbl)
                
                # Check if the target is a number or a text label
                if (lbl ~ /^[0-9]+$/) {
                    # It's a number, so use it directly.
                    new_list = new_list (new_list == "" ? "" : ", ") lbl
                } else if (lbl in labels) {
                    # It's a known text label, replace it with its number.
                    new_list = new_list (new_list == "" ? "" : ", ") labels[lbl]
                } else {
                    # It's an unknown text label.
                    new_list = new_list (new_list == "" ? "" : ", ") "INVALID_LABEL"
                }
            }
            sub(labels_str, new_list, line)
            print line " \\ ! " labels_str
        } else if (match(line, /^[[:space:]]*(GOTO|GOSUB)[[:space:]]+([a-zA-Z0-9_]+)/, m)) {
            op = m[1]; target = m[2]
            
            # Check if the target is a number or a text label
            if (target ~ /^[0-9]+$/) {
                # It's already a line number, so print the original line.
                print line
            } else if (target in labels) {
                # It's a text label, so replace it with its number.
                print indent_str op " " labels[target] " \\ ! " target
            } else {
                # It's an unknown text label.
                print indent_str "REM ERROR: Label not found: " target
            }
        } else if (match(line, /^[[:space:]]*([a-zA-Z][a-zA-Z0-9_]*):/, m)) {
            label = m[1]
            if (label in labels) print indent_str labels[label] ": \\ ! " label
            else print line " \ ! ERROR: Unindexed Label"

        # 4. SELECT CASE Block Replacement
        } else if (match(line, /^[[:space:]]*SELECT[[:space:]]+(.*)/, m)) {
            in_select = 1; select_var = m[1]; select_endif_count = 0; is_first_case = 1
            match(line, /^([[:space:]]*)/); select_indent = substr(line, RSTART, RLENGTH)
        } else if (in_select && match(line, /^[[:space:]]*CASE[[:space:]]+DEFAULT/)) {
            print select_indent "ELSE"
        } else if (in_select && match(line, /^[[:space:]]*CASE[[:space:]]+(.*)/, m)) {
            vals_str = m[1]; split(vals_str, vals, ","); condition = ""
            for (v in vals) {
                val = vals[v]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
                condition = condition (condition == "" ? "" : " OR ") select_var "=" val
            }
            if (is_first_case) print select_indent "IF " condition " THEN"
            else print select_indent "ELSE IF " condition " THEN"
            select_endif_count++; is_first_case = 0
        } else if (in_select && match(line, /^[[:space:]]*ENDSELECT/)) {
            endif_line = select_indent
            for (c = 1; c <= select_endif_count; c++) {
                endif_line = endif_line (c > 1 ? " / " : "") "ENDIF"
            }
            print endif_line
            in_select = 0
        
        # Default action: Print the (possibly modified) line
        } else {
            print line
        }
    }
}