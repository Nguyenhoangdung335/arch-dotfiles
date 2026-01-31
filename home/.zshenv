export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export SPACESHIP_CONFIG="$ZDOTDIR/spaceship.zsh"

export EDITOR=nvim
export VISUAL=nvim

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export HISTFILE="$ZDOTDIR/.zhistory"
export HISTSIZE=10000
export SAVEHIST=10000
export ZVM_SYSTEM_CLIPBOARD_ENABLED="true"

export ATAC_KEY_BINDINGS="~/.config/atac/modules/vim_key_binding.toml"

# Ccache and CMake settings
# export CC="ccache clang"
# export CXX="ccache clang++"
export CMAKE_GENERATOR=Ninja

# Programming languages bin/ directory paths environment variables
# export PATH="$PATH:$HOME/.local/share/go/bin/"
# export PATH="$PATH:$HOME/.local/share/go-local/pkg/bin/"
