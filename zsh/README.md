# ZSH Plugin - Goose in Podman

**Status: Planned - Not Yet Implemented**

This directory will contain a ZSH plugin equivalent to the Fish shell plugin, providing the same functionality for ZSH users.

## Planned Features

- Same container launcher functionality as Fish plugin
- ZSH-specific completions
- Integration with Oh My Zsh and other ZSH frameworks
- Equivalent hook system for customization

## Contributing

If you're interested in implementing the ZSH plugin, please:

1. Follow the same design patterns as the Fish plugin
2. Maintain feature parity
3. Provide installation instructions for common ZSH plugin managers (Oh My Zsh, zinit, antigen, etc.)

See the Fish implementation in `../fish/conf.d/container-launcher.fish` as a reference.

## Design Notes

The ZSH implementation should:

1. **Function Names**: Keep the same public API
   - `goose-container`
   - `copilot-container`
   - `goose-podman` (alias)

2. **Hook Functions**: Same names for cross-shell compatibility
   - `container-work-env-vars`
   - `container-work-mounts`

3. **Structure**: Follow ZSH plugin conventions
   ```
   zsh/
   ├── goose-in-podman.plugin.zsh     # Main plugin file
   ├── functions/                      # Function definitions
   │   ├── __container_launcher
   │   ├── goose-container
   │   └── copilot-container
   └── completions/                    # ZSH completions
       ├── _goose-container
       └── _copilot-container
   ```

4. **Array Handling**: ZSH arrays are 1-indexed (unlike Fish)
   - Adjust array slicing: `$argv[2,-1]` instead of `$argv[2..-1]`
   - Use `${array[@]}` for all elements

5. **Conditionals**: Convert Fish's `test` to ZSH's `[[ ]]`
   - `test -e $file` → `[[ -e $file ]]`
   - `test "$var" = "value"` → `[[ "$var" == "value" ]]`

6. **String Manipulation**: ZSH has powerful parameter expansion
   - `string split` → `${variable//separator/ }`
   - `string match` → pattern matching with `=~` or `${variable%%pattern}`

7. **Local Variables**: Use `local` instead of `set -l`

8. **Environment Variables**: Use `export` instead of `set -x`

## Example Structure

```zsh
# goose-in-podman.plugin.zsh

# Internal helper functions
__container_print_verbose() {
    [[ -n "$CONTAINER_VERBOSE" ]] && echo "$@" >&2
}

__container_launcher() {
    local image="$1"
    local tool_cmd="$2"
    shift 2
    local remaining_args=("$@")

    # ... implementation ...
}

# Public functions
goose-container() {
    export GOOSE_DISABLE_KEYRING=1
    export LANGFUSE_ENABLED=false

    __container_launcher "ai-ubuntu:latest" "goose" "$@"

    unset GOOSE_DISABLE_KEYRING
    unset LANGFUSE_ENABLED
}

copilot-container() {
    __container_launcher "ai-ubuntu:latest" "copilot" "$@"
}

# Alias for backwards compatibility
alias goose-podman=goose-container
```

## Installation (Planned)

### Oh My Zsh
```zsh
# Clone to custom plugins directory
git clone https://github.com/ford-personal/mruss100.goose-in-podman-example \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/goose-in-podman

# Add to plugins in ~/.zshrc
plugins=(... goose-in-podman)
```

### zinit
```zsh
zinit light ford-personal/mruss100.goose-in-podman-example/zsh
```

### antigen
```zsh
antigen bundle ford-personal/mruss100.goose-in-podman-example/zsh
```

### Manual
```zsh
# Source in ~/.zshrc
source ~/goose-in-podman-example/zsh/goose-in-podman.plugin.zsh
```

## Help Wanted

We're looking for ZSH users to help implement this plugin. If you're interested, please:

1. Fork the repository
2. Implement the ZSH plugin following the design notes above
3. Test with different ZSH configurations
4. Submit a pull request

Feel free to reference or port the Fish shell implementation, but ensure idiomatic ZSH code.
