# hop: jump between dev repos, worktrees and package.json dirs.
#
#   hop myrepo                 repo root
#   hop myrepo.api             package dir, dot notation
#   hop myrepo@feature-x       worktree
#   hop myrepo.api/src         subpath
#   hop -                      previous dir
#   hop                        first scan root
#
# Keys come from a cached index. `hop -r` rebuilds; otherwise stale past
# HOP_TTL_MINUTES.

: "${HOP_ROOTS:=$HOME/dev}"                 # colon-separated
: "${HOP_INDEX_FILE:=${XDG_CACHE_HOME:-$HOME/.cache}/hop/index}"
: "${HOP_TTL_MINUTES:=1440}"                # a day
: "${HOP_MAX_DEPTH:=6}"
: "${HOP_PRUNE_NAMES:=node_modules dist build vendor temp coverage}"

# TSV: container_key, container_path, relative_subpath. Empty subpath = the
# container itself. Takes $prune_expression from its caller.
_hop_scan_container() {
    local container_key=$1 container_path=$2
    local manifest_path relative_directory

    printf '%s\t%s\t\n' "$container_key" "$container_path"

    while IFS= read -r manifest_path; do
        relative_directory=${manifest_path%/package.json}
        [ "$relative_directory" = "$container_path" ] && continue   # own manifest
        printf '%s\t%s\t%s\n' "$container_key" "$container_path" \
            "${relative_directory#"$container_path"/}"
    done < <(
        find "$container_path" -maxdepth "$HOP_MAX_DEPTH" \
            \( "${prune_expression[@]}" \) -prune \
            -o -name package.json -print 2>/dev/null
    )
}

# Shortest subpath suffix unique within its container: apps/services/api tries
# api, services.api, apps.services.api. Collisions lengthen, never shadow.
# Dedupes on key, first wins.
_hop_derive_keys() {
    awk -F'\t' '
        {
            container[NR] = $1; container_path[NR] = $2; sub_path[NR] = $3
            if ($3 == "") next

            depth[NR] = split($3, segments, "/")
            suffix = ""
            for (position = depth[NR]; position >= 1; position--) {
                suffix = (suffix == "") ? segments[position] : segments[position] "." suffix
                take = depth[NR] - position + 1
                candidate[NR, take] = suffix
                occurrences[$1, take, suffix]++
            }
        }
        END {
            for (record = 1; record <= NR; record++) {
                key = container[record]
                target_path = container_path[record]

                if (sub_path[record] != "") {
                    chosen = candidate[record, depth[record]]
                    for (take = 1; take <= depth[record]; take++) {
                        if (occurrences[key, take, candidate[record, take]] == 1) {
                            chosen = candidate[record, take]
                            break
                        }
                    }
                    key = key "." chosen
                    target_path = target_path "/" sub_path[record]
                }

                if (!emitted[key]++) print key "\t" target_path
            }
        }
    '
}

_hop_build_index() {
    local index_directory=${HOP_INDEX_FILE%/*}
    local temporary_index="$HOP_INDEX_FILE.$$"
    local root_directory container_path container_name
    local repository_name worktree_path worktree_name prune_name saved_ifs
    local -a scan_roots=() prune_expression=( -name '.*' )

    mkdir -p "$index_directory" || return 1

    for prune_name in $HOP_PRUNE_NAMES; do
        prune_expression+=( -o -name "$prune_name" )
    done

    saved_ifs=$IFS
    IFS=:
    read -r -a scan_roots <<< "$HOP_ROOTS"
    IFS=$saved_ifs

    {
        for root_directory in "${scan_roots[@]}"; do
            [ -d "$root_directory" ] || continue
            for container_path in "$root_directory"/*/; do
                container_path=${container_path%/}
                [ -d "$container_path" ] || continue
                container_name=${container_path##*/}
                case $container_name in .*) continue ;; esac

                if [ "${container_name%.worktrees}" != "$container_name" ]; then
                    repository_name=${container_name%.worktrees}
                    for worktree_path in "$container_path"/*/; do
                        worktree_path=${worktree_path%/}
                        [ -d "$worktree_path" ] || continue
                        worktree_name=${worktree_path##*/}
                        _hop_scan_container \
                            "$repository_name@$worktree_name" "$worktree_path"
                    done
                else
                    _hop_scan_container "$container_name" "$container_path"
                fi
            done
        done
    } | _hop_derive_keys | LC_ALL=C sort -t'	' -k1,1 > "$temporary_index"

    mv -f "$temporary_index" "$HOP_INDEX_FILE"
}

# hop only. Completion must never stall on a rebuild.
_hop_ensure_index() {
    [ -s "$HOP_INDEX_FILE" ] || { _hop_build_index; return; }
    if [ -n "$(find "$HOP_INDEX_FILE" -mmin "+$HOP_TTL_MINUTES" 2>/dev/null)" ]; then
        _hop_build_index
    fi
    return 0
}

_hop_lookup() {
    awk -F'\t' -v wanted="$1" '$1 == wanted { print $2; exit }' "$HOP_INDEX_FILE"
}

# Exact, then unique prefix, then unique case-insensitive substring.
# Emits key<TAB>path. Candidates to stderr when ambiguous.
_hop_resolve() {
    local wanted=$1 selection
    local -a matches=()

    mapfile -t matches < <(
        awk -F'\t' -v wanted="$wanted" '$1 == wanted { print; exit }' "$HOP_INDEX_FILE")

    [ ${#matches[@]} -eq 0 ] && mapfile -t matches < <(
        awk -F'\t' -v prefix="$wanted" 'index($1, prefix) == 1' "$HOP_INDEX_FILE")

    [ ${#matches[@]} -eq 0 ] && mapfile -t matches < <(
        awk -F'\t' -v needle="$wanted" '
            BEGIN { needle = tolower(needle) }
            index(tolower($1), needle) > 0
        ' "$HOP_INDEX_FILE")

    case ${#matches[@]} in
        0) printf 'hop: no target matching %s\n' "$wanted" >&2; return 1 ;;
        1) printf '%s\n' "${matches[0]}"; return 0 ;;
    esac

    if command -v fzf >/dev/null 2>&1 && [ -t 0 ]; then
        selection=$(printf '%s\n' "${matches[@]}" | fzf --select-1 --exit-0 \
            --delimiter='\t' --with-nth=1 --query="$wanted")
        [ -n "$selection" ] || return 1
        printf '%s\n' "$selection"
        return 0
    fi

    printf 'hop: %s is ambiguous:\n' "$wanted" >&2
    printf '  %s\n' "${matches[@]%%$'\t'*}" >&2
    return 1
}

hop() {
    local action=jump print_only=0 target=''
    local key_part sub_path resolved_path

    while [ $# -gt 0 ]; do
        case $1 in
            -p|--path)    print_only=1 ;;
            -l|--list)    action=list ;;
            -r|--reindex) action=reindex ;;
            -h|--help)    action=help ;;
            -)            action=back ;;
            --)           shift; [ $# -gt 0 ] && target=$1 ;;
            -*)           printf 'hop: unknown flag %s\n' "$1" >&2; return 2 ;;
            *)            [ -z "$target" ] ||
                              { printf 'hop: one target at a time\n' >&2; return 2; }
                          target=$1 ;;
        esac
        shift
    done

    case $action in
        help)
            cat <<'HOP_USAGE_EOF'
hop [-p|--path] [target[/subpath]]

  <repo>            repo root                hop myrepo
  <repo>.<pkg>      package.json directory   hop myrepo.api
  <repo>@<worktree> git worktree             hop myrepo@feature-x
  -                 previous directory

  -p, --path        print the path, do not cd
  -l, --list        list every indexed key
  -r, --reindex     rebuild the cache now
HOP_USAGE_EOF
            return 0 ;;
        list)
            _hop_ensure_index
            cut -f1 "$HOP_INDEX_FILE"
            return 0 ;;
        reindex)
            _hop_build_index || return 1
            printf 'hop: indexed %s targets\n' \
                "$(wc -l < "$HOP_INDEX_FILE" | tr -d ' ')"
            return 0 ;;
        back)
            [ "$print_only" -eq 1 ] && { printf '%s\n' "$OLDPWD"; return 0; }
            cd - >/dev/null || return
            return 0 ;;
    esac

    _hop_ensure_index

    if [ -z "$target" ]; then
        resolved_path=${HOP_ROOTS%%:*}
    else
        key_part=${target%%/*}
        sub_path=''
        [ "$target" != "$key_part" ] && sub_path=${target#*/}

        resolved_path=$(_hop_resolve "$key_part") || return 1
        resolved_path=${resolved_path#*$'\t'}
        [ -n "$sub_path" ] && resolved_path="$resolved_path/${sub_path%/}"
    fi

    if [ ! -d "$resolved_path" ]; then
        printf 'hop: %s is not a directory\n' "$resolved_path" >&2
        return 1
    fi

    if [ "$print_only" -eq 1 ]; then
        printf '%s\n' "$resolved_path"
    else
        cd "$resolved_path" || return
    fi
}

# Keys nest under this one, so completion holds the space back for . or @.
_hop_key_has_children() {
    awk -F'\t' -v parent="$1" '
        index($1, parent ".") == 1 || index($1, parent "@") == 1 { exit 0 }
        END { exit 1 }
    ' "$HOP_INDEX_FILE"
}

_hop_complete() {
    local current_word=${COMP_WORDS[COMP_CWORD]}
    local key_part sub_path container_path candidate_path indexed_keys

    [ -s "$HOP_INDEX_FILE" ] || _hop_build_index   # never a TTL rebuild here

    case $current_word in
        -*) mapfile -t COMPREPLY < <(compgen -W \
                '-p --path -l --list -r --reindex -h --help' -- "$current_word")
            return ;;
    esac

    if [[ $current_word == */* ]]; then             # subpath: plain dir completion
        key_part=${current_word%%/*}
        sub_path=${current_word#*/}
        container_path=$(_hop_lookup "$key_part")
        [ -n "$container_path" ] || return

        COMPREPLY=()
        for candidate_path in "$container_path/$sub_path"*/; do
            [ -d "$candidate_path" ] || continue
            candidate_path=${candidate_path%/}
            case " $HOP_PRUNE_NAMES " in            # same noise the index skips
                *" ${candidate_path##*/} "*) continue ;;
            esac
            COMPREPLY+=( "$key_part/${candidate_path#"$container_path"/}/" )
        done
        compopt -o nospace
        return
    fi

    indexed_keys=$(cut -f1 "$HOP_INDEX_FILE")
    mapfile -t COMPREPLY < <(compgen -W "$indexed_keys" -- "$current_word")

    if [ "${#COMPREPLY[@]}" -eq 1 ] && _hop_key_has_children "${COMPREPLY[0]}"; then
        compopt -o nospace
    fi
}

complete -F _hop_complete hop
