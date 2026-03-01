# Remplacer klocal par un simple statut basé sur la sortie de la commande précédente
ret_status="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"
PROMPT='${ret_status} %{$fg[magenta]%}%n%{$reset_color%} [%{$fg_bold[green]%}%D{%d/%m %H:%M}%{$reset_color%}] %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)'

# Configuration du prompt pour Git
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"