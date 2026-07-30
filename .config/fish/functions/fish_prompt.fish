function fish_prompt
    echo
    set -l last_status $status
    if test $last_status -ne 0
        printf '%s%s%s ' (set_color red) $last_status (set_color normal)
    end
    printf '%s %s' (_compress_dir) (fish_git_prompt)
    printf '\nλ '
end
