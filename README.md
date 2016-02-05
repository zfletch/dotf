# Dotf

Preprocessor for dotfiles. Manage dotfiles with machine-specific tags then compile and link them.

## Example .bashrc (~/.dotf/dofiles/bashrc)

```bash
[ -z "$PS1" ] && return

# ~~~ location /etc/bashrc server router ~~~

# ~~~ only osx ~~~
alias ls='ls -G'
if [ -f `brew --prefix`/etc/bash_completion ]; then
  source `brew --prefix`/etc/bash_completion
fi
# ~~~ only linux
alias ls='ls --color=auto'
# ~~~ include all

alias grep='grep --color=auto'

# ~~~ only red ~~~
PS1='\[\033[01;37m\]\u@\h$(__git_ps1)\[\033[01;31m\] \w\[\033[01;37m\] \$\[\033[00m\] '
# ~~~ only blue ~~~
PS1='\[\033[01;37m\]\u@\h$(__git_ps1)\[\033[01;34m\] \w\[\033[01;37m\] \$\[\033[00m\] '
# ~~~ include all ~~~

# ~~~ exclude router ~~~
alias vi=vim
```

## How to use

First, run `dotf init`. This creates the `~/.dotf` directory. The structure of that directory is:

```
.dotf/
  dotfiles/
    vimrc
    bashrc
    etc.
  .compiled/
  key
  tags
```

Now you can put your conf files in`./dotf/dotfiles` (and manage them with source control).
Running `dotf run` compiles and links all of the dotfiles.

### Tags

If you run the command `dotf tags` you can see a list of tags for the current machine.
By default, every machine should have the tag `all`. You can add tags by running `dotf tags tag1 tag2 ...`.
You can also manually manage tags by modifying the file `~/./dotf/tags`.

### Key

Running the command `dotf key` will show the current key. By default it's `~~~`. You can change it by
running `dotf key new_key` or manually editing `~/.dotf/key`.

### Compiling and linking

The command `dotf run` compiles and links all the files within `~/.dotf/dotfiles`.
The compiled files live in the `~/.dotf/.compiled/` directory.
By default, the linked location for `~/.dotf/dotfiles/<filename>` is `~/.<filename>`, but
that can be overridden with the `location` pragma (see below).

### Pragmas (or pragmata?)

Within a dotfile, you can use the following pragmas to compile things differently on different machines.
All pragmas have to be surrounded by they `key` (by default `~~~`).

#### Include

* `~~~ include tag [tags ...] ~~~`
* If the current machine has a tag matching any of the tags, then include this line and following lines in the compiled output.

#### Exclude

* `~~~ exclude tag [tags ...] ~~~`
* If the current machine has a tag matching any of the tags, then exclude this line and following lines in the compiled output.

#### Only

* `~~~ only tag [tags ...] ~~~`
* If the current machine has a tag matching any of the tags, then include this line and following lines in the compiled output. Otherwise, exclude this line and following lines from the compiled output.

#### Location

* If the current machine has a tag matching any of the tags, then link the compiled file to the given path.
* `~~~ location path tag [tags ...] ~~~`
