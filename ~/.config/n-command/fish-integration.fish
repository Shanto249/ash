# n-command fish integration for trigger word "avarice"
# This script enables interception of any command containing the trigger word

# Configuration
set -g TRIGGER_WORD "avarice"
set -g N_COMMAND "n"
set -g DEBUG_MODE true

# Helper function to log debug messages
function n_debug_log
    if test "$DEBUG_MODE" = true
        echo "[n-command debug] $argv" >&2
    end
end

# Function to check if this is the n command itself
function __n_command_is_n_command
    set -l cmd $argv[1]
    string match -q "$N_COMMAND *" -- "$cmd"
    return $status
end

# This is our key function that intercepts pre-execution
function __n_command_intercept_pre_execute --on-event fish_preexec
    set -l cmd $argv
    
    n_debug_log "Processing command: $cmd"
    
    # Skip if it's n command or doesn't contain our trigger word
    if not string match -q "*$TRIGGER_WORD*" -- "$cmd"
        n_debug_log "No trigger word, skipping"
        return
    end
    
    # Skip if it's a direct invocation of our trigger command or n command
    if string match -q "$TRIGGER_WORD *" -- "$cmd"; or string match -q "$N_COMMAND *" -- "$cmd"
        n_debug_log "Direct invocation, allowing normal execution: $cmd"
        return
    end
    
    # We've got a trigger word in a regular command, time to intercept!
    echo "Intercepted: $cmd"
    echo "Running: $N_COMMAND \"$cmd\""
    
    # Block the original command by returning false
    # This prevents the original command from executing
    return 1
end

# This is a complementary function that runs after we block the original
function __n_command_execute_intercepted --on-event fish_command_not_found
    set -l cmd $argv
    
    # Only process if it has our trigger word
    if string match -q "*$TRIGGER_WORD*" -- "$cmd"
        n_debug_log "Executing intercepted command via n: $cmd"
        
        # Run n with the entire original command
        eval "$N_COMMAND \"$cmd\""
    end
end

# Define our direct command function
function $TRIGGER_WORD
    $N_COMMAND $argv
end

# Create additional command helpers for common prefixes
function hey
    # If first arg is the trigger word (or contains it), use n
    if string match -q "*$TRIGGER_WORD*" -- "$argv[1]"
        set -l full_cmd "hey $argv"
        echo "Intercepted: $full_cmd"
        echo "Running: $N_COMMAND \"$full_cmd\""
        $N_COMMAND "$full_cmd"
    else
        # Otherwise, pass through to the real 'hey' command if it exists
        command hey $argv
    end
end

function please
    # If any arg contains the trigger word, use n
    set -l has_trigger 0
    for arg in $argv
        if string match -q "*$TRIGGER_WORD*" -- "$arg"
            set has_trigger 1
            break
        end
    end
    
    if test $has_trigger -eq 1
        set -l full_cmd "please $argv"
        echo "Intercepted: $full_cmd"
        echo "Running: $N_COMMAND \"$full_cmd\""
        $N_COMMAND "$full_cmd"
    else
        # Otherwise, pass through
        command please $argv
    end
end

echo "n-command fish integration installed with trigger word: $TRIGGER_WORD"
echo "You can now use commands in these formats:"
echo "  1. $TRIGGER_WORD list files            (direct command)"
echo "  2. hey $TRIGGER_WORD, list files       (trigger word in sentence)"
echo "  3. show me files $TRIGGER_WORD please  (trigger word anywhere)"
echo "  4. Commands with hey or please are also supported directly" 