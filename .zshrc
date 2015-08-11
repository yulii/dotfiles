export LANG="ja_JP.UTF-8"

PROMPT="%n %# "
RPROMPT="[%/]"

HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

fpath=(/usr/local/share/zsh-completions $fpath)

setopt IGNORE_EOF
setopt NO_FLOW_CONTROL
setopt NO_BEEP

bindkey '^o' history-beginning-search-backward-end
bindkey '^r' history-incremental-pattern-search-backward
bindkey '^s' history-incremental-pattern-search-forward

autoload -Uz add-zsh-hook
autoload -Uz chpwd_recent_dirs cdr
add-zsh-hook chpwd  chpwd_recent_dirs

autoload -U compinit
compinit
zstyle ':completion:*:default' menu select=2
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end

autoload -Uz select-word-style
select-word-style dafault
zstyle ':zle:*' word-chars " /=;@:{},|"
zstyle ':zle:*' word-style unspecified

autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:*' formats "%F{green}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'

function _update_vcs_info_msg() {
  LANG=en_US.UTF-8 vcs_info
  RPROMPT="[%/]${vcs_info_msg_0_}"
}

add-zsh-hook precmd _update_vcs_info_msg

autoload -Uz zmv

if [[ -f $HOME/.zsh/antigen/antigen.zsh ]]; then
  source $HOME/.zsh/antigen/antigen.zsh
  antigen bundle zsh-users/zsh-syntax-highlighting
  antigen apply
fi

if which rbenv  > /dev/null; then eval "$(rbenv init -)";   fi
#if which direnv > /dev/null; then eval "$(direnv hook $0)"; fi

export PATH=$HOME/.cabal/bin:$HOME/.cabal-sandbox/bin:$PATH

