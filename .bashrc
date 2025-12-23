#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

alias vim='nvim'

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_kernel
ssh-add ~/.ssh/id_ed25519_sarangvehale
ssh-add ~/.ssh/id_ed25519_iitm
#ssh-add ~/.ssh/id_ed25519_extrastufff054
. "$HOME/.cargo/env"

alias syncnotes="systemctl --user start notes_manual_sync"
export PATH=~/.local/bin:$PATH
