# heroku.vim

A Vim plugin for interacting with Heroku.  Yes really.  Provided is a
`:Heroku` command that wraps the [Heroku CLI][], featuring some pretty wicked
tab complete.  Plus it adds a command wrapper for each Heroku remote in your
Git config, so `:Staging console` is only a few keystrokes away.

[Heroku CLI]: https://devcenter.heroku.com/articles/heroku-cli

## Installation

Install using your favorite package manager, or use Vim's built-in package
support:

    mkdir -p ~/.vim/pack/tpope/start
    cd ~/.vim/pack/tpope/start
    git clone https://tpope.io/vim/heroku.git
    vim -u NONE -c "helptags heroku/doc" -c q

You may also want to install [dispatch.vim][] and [fugitive.vim][] for
asynchronous command execution and better Git repository detection,
respectively.

[dispatch.vim]: https://github.com/tpope/vim-dispatch
[fugitive.vim]: https://github.com/tpope/vim-fugitive

## License

Copyright © Tim Pope.  Distributed under the same terms as Vim itself.
See `:help license`.
