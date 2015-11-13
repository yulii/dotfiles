export LANG="ja_JP.UTF-8"

PROMPT='[%*] [%n@%m: %/]
%# '

setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt share_history
HISTFILE=$HOME/.histories/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

setopt auto_pushd

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
  PROMPT="[%*] [%n@%m: %/]${vcs_info_msg_0_}
%# "
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
if [ -f .plex/function.sh ]; then
  source .plex/function.sh
fi
if [ -f .plex/alias.sh ]; then
  source .plex/alias.sh
fi


export PATH=/usr/local/bin:$HOME/.cabal/bin:$HOME/.cabal-sandbox/bin:$PATH

# bundle config --global jobs `expr $(sysctl -n hw.ncpu) - 1`

alias updatedb='sudo /usr/libexec/locate.updatedb'

