# bash completion for acdg
#
# Install:
#   ~/.local/share/bash-completion/completions/acdg
# OR source from .bashrc:
#   source <path-to-acdg.bash>

_acdg_completion() {
    local cur prev cmd
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cmd="${COMP_WORDS[1]}"

    # Top-level: 9 namespaces + global flags.
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "auth patient family assessment care protection lookup team health --help --bff --output --quiet" -- ${cur}) )
        return 0
    fi

    # Sub-command level (depth 2): per-namespace verbs.
    if [[ ${COMP_CWORD} -eq 2 ]]; then
        case "$cmd" in
            auth)
                COMPREPLY=( $(compgen -W "login status logout refresh" -- ${cur}) ) ;;
            patient)
                COMPREPLY=( $(compgen -W "list get audit register admit discharge readmit withdraw" -- ${cur}) ) ;;
            family)
                COMPREPLY=( $(compgen -W "add remove assign-caregiver update-identity" -- ${cur}) ) ;;
            assessment)
                COMPREPLY=( $(compgen -W "housing socioeconomic work-income education health community-support social-health-summary" -- ${cur}) ) ;;
            care)
                COMPREPLY=( $(compgen -W "appointment intake" -- ${cur}) ) ;;
            protection)
                COMPREPLY=( $(compgen -W "violation referral placement-history" -- ${cur}) ) ;;
            lookup)
                COMPREPLY=( $(compgen -W "get batch create update toggle request" -- ${cur}) ) ;;
            team)
                COMPREPLY=( $(compgen -W "list register get deactivate reactivate reset-password role" -- ${cur}) ) ;;
        esac
        return 0
    fi

    # Sub-sub-command level (depth 3): only `lookup request` and `team role`.
    if [[ ${COMP_CWORD} -eq 3 ]]; then
        local subcmd="${COMP_WORDS[2]}"
        if [[ "$cmd" == "lookup" && "$subcmd" == "request" ]]; then
            COMPREPLY=( $(compgen -W "list create approve reject" -- ${cur}) )
            return 0
        fi
        if [[ "$cmd" == "team" && "$subcmd" == "role" ]]; then
            COMPREPLY=( $(compgen -W "assign deactivate reactivate" -- ${cur}) )
            return 0
        fi
    fi

    # Flag completion: when prev starts with `--`, suggest values for known flags.
    if [[ ${cur} == --* ]]; then
        COMPREPLY=( $(compgen -W "--help --output --bff --quiet --from-yaml" -- ${cur}) )
        return 0
    fi

    if [[ ${prev} == --output ]]; then
        COMPREPLY=( $(compgen -W "table json yaml auto" -- ${cur}) )
        return 0
    fi
}

complete -F _acdg_completion acdg
