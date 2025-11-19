function fish_git_prompt
  set -l branch (git branch --show-current 2>/dev/null)
  if [ -n "$branch" ]
    set -l dirty (git status --porcelain 2>/dev/null)
    if [ -n "$dirty" ]
      printf '(%s*)' $branch
    else
      printf '(%s)' $branch
    end
  end
end