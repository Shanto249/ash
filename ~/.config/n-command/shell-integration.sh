#!/bin/bash
# n-command shell integration for trigger word "avarice"
# This simplified approach uses functions and aliases to handle arbitrary commands

# Configuration
TRIGGER_WORD="avarice"
N_COMMAND="n"
DEBUG_MODE=true  # Enable logging for troubleshooting

# Helper function to log messages when debug is enabled
debug_log() {
    if [ "$DEBUG_MODE" = true ]; then
        echo "[$(date +%T.%N)] [n-command debug] $1" >&2
    fi
}

# Define direct command function
$TRIGGER_WORD() {
    debug_log "Direct '$TRIGGER_WORD' function called with args: [$*]"
    $N_COMMAND "$@"
}

# The core function that checks any command for our trigger word
__n_command_handler() {
    local cmd_name="$1"
    shift  # Remove the command name
    local full_cmd="$cmd_name $*"
    
    debug_log "Handler called for: [$cmd_name] with args: [$*]"
    debug_log "Full command: [$full_cmd]"
    
    # Check if args contain our trigger word
    if [[ "$*" == *"$TRIGGER_WORD"* ]]; then
        debug_log "Trigger word found in arguments"
        echo "Intercepted: $full_cmd"
        echo "Running: $N_COMMAND \"$full_cmd\""
        $N_COMMAND "$full_cmd"
        return 0
    fi
    
    # No trigger word, try to execute the original command
    debug_log "No trigger word, executing original: $cmd_name $*"
    command "$cmd_name" "$@" 2>/dev/null || {
        echo "Command not found: $cmd_name"
        return 1
    }
}

# Set up aliases for common command prefixes
# These will intercept commands before the shell tries to execute them
setup_aliases() {
    # List of common command prefixes to intercept
    local prefixes=(
        "hey" "hello" "hi" "please" "show" "tell" "find" "list" "get" "create"
        "make" "run" "start" "begin" "open" "close" "help" "what" "when" "where"
        "why" "who" "how" "give" "let" "can" "could" "would" "should" "will"
        "do" "does" "is" "are" "am" "was" "were" "be" "been" "being" "have"
        "has" "had" "may" "might" "must" "shall" "should" "will" "would"
    )
    
    for prefix in "${prefixes[@]}"; do
        debug_log "Creating alias for: $prefix"
        # The \ before the function name prevents further alias expansion
        alias "$prefix"="__n_command_handler $prefix"
    done
    
    debug_log "Created aliases for ${#prefixes[@]} common prefixes"
}

# Set up our command interception
setup_aliases

# Export the necessary functions
export -f $TRIGGER_WORD
export -f __n_command_handler
export -f debug_log

# Also create an alias for common misspellings of avarice
alias avaric="$TRIGGER_WORD"
alias avrice="$TRIGGER_WORD"
alias avarace="$TRIGGER_WORD"

echo "n-command shell integration (function aliases) installed."
echo "Trigger word: $TRIGGER_WORD. Debug mode: $DEBUG_MODE."
echo "Commands like 'hey avarice show files' will now be intercepted."
echo "Supported command prefixes: hey, please, show, tell, find, and many others." 