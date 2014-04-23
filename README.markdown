# heroku.vim

A Vim plugin for interacting with Heroku.  Yes really.  Provided is an `:Hk`
command that wraps both the [Heroku toolbelt][] and [hk][], with some pretty
wicked tab complete for the latter.  Plus it adds a command wrapper for each
Heroku remote in your Git config, so `:Staging console` is only a few
keystrokes away.

[Heroku toolbelt]: https://toolbelt.heroku.com/
[hk]: https://github.com/heroku/hk

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

You might also like [heroku-remote][], to set up all the different remotes for
your app in one go with `heroku remote:setup`, and [heroku-binstubs][], to
create individual scripts that parallel the commands provided by heroku.vim.

    heroku plugins:install https://github.com/tpope/heroku-remote.git
    heroku plugins:install https://github.com/tpope/heroku-binstubs.git

[dispatch.vim]: https://github.com/tpope/vim-dispatch
[fugitive.vim]: https://github.com/tpope/vim-fugitive
[heroku-remote]: https://github.com/tpope/heroku-remote
[heroku-binstubs]: https://github.com/tpope/heroku-binstubs

## License

Copyright © Tim Pope.  Distributed under the same terms as Vim itself.
See `:help license`.
