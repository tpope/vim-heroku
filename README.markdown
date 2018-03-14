# heroku.vim

A Vim plugin for interacting with Heroku.  Yes really.  Provided is a
`:Heroku` command that wraps the [Heroku CLI][], featuring some pretty wicked
tab complete.  Plus it adds a command wrapper for each Heroku remote in your
Git config, so `:Staging console` is only a few keystrokes away.

[Heroku CLI]: https://devcenter.heroku.com/articles/heroku-cli

## Installation

If you don't have a preferred installation method, I recommend
installing [pathogen.vim](https://github.com/tpope/vim-pathogen), and
then simply copy and paste:

    cd ~/.vim/bundle
    git clone git://github.com/tpope/vim-heroku.git
    git clone git://github.com/tpope/vim-dispatch.git
    git clone git://github.com/tpope/vim-fugitive.git

You technically don't need [dispatch.vim][] or [fugitive.vim][], but they help
heroku.vim with asynchronous command execution and Git repository detection,
respectively.

[dispatch.vim]: https://github.com/tpope/vim-dispatch
[fugitive.vim]: https://github.com/tpope/vim-fugitive

## License

Copyright © Tim Pope.  Distributed under the same terms as Vim itself.
See `:help license`.
