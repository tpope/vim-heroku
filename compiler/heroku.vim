" Vim compiler file

if exists("current_compiler")
  finish
endif

let current_compiler = "heroku"

CompilerSet makeprg=heroku
CompilerSet errorformat=%-G%\\e[?25h,
      \%\\&terminal=%\\C%\\%%(run%\\\|console%\\\|psql%\\\|pg:psql%\\\|local%\\\|local:start%\\)%\\>:%\\@!%\\ze%.%#,
      \%+I%.%#
