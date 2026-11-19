# Silence default fish greeting so Ghostty opens cleanly
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
