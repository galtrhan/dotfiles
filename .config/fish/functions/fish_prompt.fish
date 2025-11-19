function fish_prompt
  set -l last_status $status
  if test $last_status -ne 0
    printf '%s%s%s ' (set_color red) $last_status (set_color normal)
  end
  printf '%s ' (fish_git_prompt)
  printf '󰘧 '
end