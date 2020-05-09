alias dotfiles-awk-tsv="awk -F \"\t\""
alias dotfiles-group-by-count="sort | uniq -c | sort -nr"
alias dotfiles-docker-clean-all='docker stop $(docker ps -q) && docker rmi $(docker images -q) -f'
