# Silence default fish greeting
set -g fish_greeting ""

# Custom window title clearly identifying Ghostty + active directory/command
function fish_title
  set -l cmd (status current-command)
  if test "$cmd" = "fish"
    echo "Ghostty · "(prompt_pwd)
  else
    echo "Ghostty · $cmd"
  end
end

# Show iconic Ghostty mascot on fresh interactive Ghostty tabs
if status is-interactive; and set -q GHOSTTY_RESOURCES_DIR; and not set -q __GHOSTTY_BANNER_SHOWN
  set -g __GHOSTTY_BANNER_SHOWN 1
  set -l c1 (set_color brblue)
  set -l c2 (set_color cyan)
  set -l c3 (set_color brwhite)
  set -l dim (set_color brblack)
  set -l rst (set_color normal)
  printf "%s      .-.%s\n" $c1 $rst
  printf "%s     ( %s● ●%s )%s   %sGhostty%s %s· %s%s\n" $c1 $c3 $c1 $rst $c2 $rst $dim (prompt_pwd) $rst
  printf "%s     |  ▽  |%s   %soc%s OpenCode  %s|%s  %socm%s Mini AI\n" $c1 $rst $c2 $dim $rst $dim $c2 $dim $rst
  printf "%s    / \\_n_/ \\%s\n" $c1 $rst
end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/maxjalo/.lmstudio/bin
# End of LM Studio CLI section

# opencode
fish_add_path /home/maxjalo/.opencode/bin

# Quick OpenCode & AI shortcuts
alias oc='opencode --auto'
alias ocp='opencode'
alias ocm='opencode mini'
alias ocweb='opencode serve'
