#!/usr/bin/env bash

version_pat='s/^tmux[^0-9]*([.0-9]+).*/\1/p'
tmux_version="$(tmux -V | sed -En "$version_pat")"
tmux setenv -g tmux_version "$tmux_version"

is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"

function setAliases(){
	tmux set -s command-alias NavigateLeft "select-pane -L"
	tmux set -s command-alias NavigateRight "select-pane -R"
	tmux set -s command-alias NavigateUp "select-pane -U"
	tmux set -s command-alias NavigateDown "select-pane -D"
	tmux set -s command-alias NavigateLast "select-pane -l"

	tmux set -s command-alias VimAwareNavigateLeft if-shell "$is_vim" "send-keys C-h" NavigateLeft
	tmux set -s command-alias VimAwareNavigateRight if-shell "$is_vim" "send-keys C-l" NavigateRight
	tmux set -s command-alias VimAwareNavigateUp if-shell "$is_vim" "send-keys C-k" NavigateUp
	tmux set -s command-alias VimAwareNavigateDown if-shell "$is_vim" "send-keys C-j" NavigateDown
	tmux set -s command-alias VimAwareNavigateLast if-shell "$is_vim" "send-keys C-\\" NavigateLast
}


function setBindings(){
	tmux bind-key -n M-h VimAwareNavigateLeft
	tmux bind-key -n M-l VimAwareNavigateRight
	tmux bind-key -n M-j VimAwareNavigateDown
	tmux bind-key -n M-k VimAwareNavigateUp
	tmux bind-key -n 'M-\\' VimAwareNavigateLast
}

function fallback(){
	tmux bind-key -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
	tmux bind-key -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
	tmux bind-key -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
	tmux bind-key -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"

	tmux if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
	  "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
	tmux if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
	  "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

	tmux bind-key -T copy-mode-vi C-h select-pane -L
	tmux bind-key -T copy-mode-vi C-j select-pane -D
	tmux bind-key -T copy-mode-vi C-k select-pane -U
	tmux bind-key -T copy-mode-vi C-l select-pane -R
	tmux bind-key -T copy-mode-vi C-\\ select-pane -l
}

if [ $(echo "${tmux_version}" < 2.4 | bc) = 1 ]; then
	fallback
	exit
fi

setAliases
setBindings
