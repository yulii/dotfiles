eval "$(/opt/homebrew/bin/brew shellenv)"

# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export PATH=$HOME/.nodebrew/current/bin:$PATH

[ -f ~/.secrets.env ] && source ~/.secrets.env
