" Location:     plugin/heroku.vim
" Maintainer:   Tim Pope <code@tpope.net>
" Version:      1.0

if exists("g:loaded_heroku") || v:version < 700 || &cp
  finish
endif
let g:loaded_heroku = 1

function! s:heroku_json(args, default) abort
  if !executable('heroku')
    return default
  endif
  let output = system('heroku '.a:args.' --json')
  if v:shell_error
    throw substitute(output, "\n$", '', '')
  elseif exists('*json_decode')
    return json_decode(output)
  endif
  let [null, false, true] = ['', 0, 1]
  let stripped = substitute(string,'\C"\(\\.\|[^"\\]\)*"','','g')
  if stripped !~# "[^,:{}\\[\\]0-9.\\-+Eaeflnr-u \n\r\t]"
    try
      return eval(substitute(string,"[\r\n]"," ",'g'))
    catch
    endtry
  endif
  throw "invalid JSON: ".string
endfunction

function! s:extract_app(args) abort
  let args = substitute(a:args, ' -- .*', '', '')
  let app = matchstr(args, '\s-\%(a\s*\|-app[= ]\s*\)\zs\S\+')
  if !empty(app)
    return app
  endif
  let remote = matchstr(args, '\s-\%(r\s*\|-remote[= ]\s*\)\zs\S\+')
  if has_key(get(b:, 'heroku_remotes', {}), remote)
    return b:heroku_remotes[remote]
  endif
  return ''
endfunction

function! s:prepare(args, app) abort
  let args = a:args
  let name = matchstr(args, '\a\S*')
  let command = s:command(name)
  if !empty(name) && empty(s:extract_app(args)) &&
        \ (get(command, 'needsApp') || get(command, 'wantsApp', 1))
    let args = substitute(args, '\S\@<=\S\@!', ' -a '.a:app, '')
  endif
  return 'heroku ' . args
endfunction

function! s:dispatch(dir, app, bang, args) abort
  if a:args ==# '&'
    let s:complete_app = a:app
    return
  endif

  let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd' : 'cd'
  let cwd = getcwd()
  let [mp, efm, cc] = [&l:mp, &l:efm, get(b:, 'current_compiler', '')]
  try
    let &l:mp = s:prepare(a:args, a:app)
    if a:args =~# '^\s*\%(run\s\+console\|console\|psql\)\>:\@!' && substitute(a:args, '-- .*', '', '') !~# ' -d\>'
      if empty(a:app)
        execute cd fnameescape(a:dir)
      else
        execute cd '~'
      endif
      let title = empty(a:app) ? 'heroku' : a:app
      let title .= ' '.matchstr(a:args, '^\s*\%(run\s\+\)\=\%(-a\s\+\S\+\s\+\)\=\zs\S\+')
      if exists(':Start')
        execute 'Start'.a:bang '-title='.escape(title, ' ') &mp
      else
        execute '!'.&mp
      endif
    else
      let b:current_compiler = 'heroku'
      let &l:efm = '%-G%\e[?25h,%+I%.%#'
      execute cd fnameescape(a:dir)
      execute (exists(':Make') == 2 ? 'Make'.a:bang : 'make!')
    endif
  finally
    let [&l:mp, &l:efm, b:current_compiler] = [mp, efm, cc]
    if empty(cc) | unlet! b:current_compiler | endif
    execute cd fnameescape(cwd)
  endtry
endfunction

unlet! s:commands
function! s:commands() abort
  if !exists('s:commands')
    let s:commands = {}
    for command in s:heroku_json('commands', {'commands': []}).commands
      let name = substitute(get(command, 'topic', '').':'.get(command, 'command', ''), ':$', '', '')
      if !empty(name)
        let s:commands[name] = command
      endif
    endfor
    lockvar s:commands
  endif
  return s:commands
endfunction

function! s:command(name, ...) abort
  let command = empty(a:name) ? {} : get(s:commands(), a:name, {})
  if a:0
    return get(command, a:1, a:0 > 1 ? a:2 : '')
  else
    return command
  endif
endfunction

let s:completers = {}
let s:app_completers = {}

function! s:completers.app(...) abort
  return map(s:heroku_json('apps -A', []), 'v:val.name')
endfunction
let s:completers.confirm = s:completers.app

function! s:completers.org(...) abort
  return map(s:heroku_json('teams', []), 'v:val.name')
endfunction

function! s:completers.plan(arg, ...) abort
  return map(s:heroku_json('addons:plans '.matchstr(a:arg, '.*\ze:'), []), 'v:val.name')
endfunction

function! s:completers.region(...) abort
  return map(s:heroku_json('regions', []), 'v:val.name')
endfunction

function! s:app_completers.release(app, ...) abort
  return map(s:heroku_json('releases -a '.a:app, []), '"v".v:val.version')
endfunction

function! s:completers.remote(...) abort
  return keys(get(b:, 'heroku_remotes', {}))
endfunction

function! s:completers.service(...) abort
  return map(s:heroku_json('addons:services', []), 'v:val.name')
endfunction

function! s:completers.space(...) abort
  return map(s:heroku_json('spaces', []), 'v:val.name')
endfunction

function! s:completers.topic(...) abort
  return sort(keys(s:commands()))
endfunction

function! s:app_completers.addon(app, ...) abort
  return map(s:heroku_json('addons -a '.a:app, []), 'v:val.name')
endfunction

function! s:completers.addon(...) abort
  return map(s:heroku_json('addons --all', []), 'v:val.name')
endfunction

function! s:completion_for(type, app, arg) abort
  let type = a:type
  if type =~ ':'
    let type = matchstr(type, '[^:]\+' . (a:arg =~ ':' ? '$' : ''))
  endif
  if !empty(a:app) && has_key(s:app_completers, type)
    return s:app_completers[type](a:app, a:arg)
  elseif has_key(s:completers, type)
    return s:completers[type](a:arg)
  else
    return []
  endif
endfunction

function! s:complete_command(cmd, app, A, L, P) abort
  let opt = matchstr(strpart(a:L, 0, a:P), ' \zs\%(-[a-z]\|--[[:alnum:]-]+[ =]\@=\)\ze\%(=\|\s*\)\S*$')
  let command = s:command(a:cmd)
  if empty(command)
    return []
  endif
  let flags = {}
  if type(get(command, 'flags')) ==# type([])
    for flag in command.flags
      let desc = flag.hasValue ? flag.name : ''
      if !empty(flag.char)
        let flags['-'.flag.char] = desc
      endif
      if !empty(flag.name)
        let flags['--'.flag.name] = desc
      endif
    endfor
    if command.needsApp || command.wantsApp
      let flags['-a'] = 'app'
      let flags['--app'] = 'app'
      let flags['-r'] = 'remote'
      let flags['--remote'] = 'remote'
    endif
  endif
  if !empty(get(flags, opt))
    return s:completion_for(flags[opt], a:app, a:A)
  endif
  let options = []
  if type(get(command, 'args')) ==# type([])
    let args = map(copy(command.args), 'v:val.name')
  else
    let args = split(tr(command.usage, '[]A-Z', '  a-z', 'g'), '\s\+')[1:-1]
  endif
  for arg in args
    let options += s:completion_for(arg, a:app, a:A)
  endfor
  return options + sort(keys(flags))
endfunction

function! s:completion_filter(results, A) abort
  return join(a:results, "\n")
endfunction

function! s:Complete(A, L, P) abort
  let s:complete_app = s:extract_app(a:L)
  if empty(s:complete_app)
    silent! execute matchstr(a:L, '\u\a*') '&'
  endif
  let cmd = matchstr(strpart(a:L, 0, a:P), '[! ]\zs\(\S\+\)\ze\s\+')
  if !empty(cmd) && cmd !=# 'help'
    let results = s:complete_command(cmd, s:complete_app, a:A, a:L, a:P)
    if !empty(s:complete_app)
      call filter(results, 'v:val !~# "^-\\%([ar]\\|-app\\|-remote\\)$"')
    endif
    return s:completion_filter(results, a:A)
  endif
  return s:completion_filter(s:completers.topic(), a:A)
endfunction

function! s:Detect(git_dir) abort
  let b:heroku_remotes = {}
  if filereadable(a:git_dir.'/config')
    for line in readfile(a:git_dir.'/config')
      let remote = matchstr(line, '^\s*\[\s*remote\s\+"\zs.*\ze"\s*\]\s*$')
      if !empty(remote)
        let alias = remote
      endif
      let app = matchstr(line, '^\s*url\s*=.*heroku.com[:/]\zs.*\ze\.git\s*$')
      if !empty(app)
        let b:heroku_remotes[alias] = app
      endif
    endfor
  endif
  for [remote, app] in items(b:heroku_remotes)
    let command = substitute(remote, '\%(^\|[-_]\+\)\(\w\)', '\u\1', 'g')
    execute 'command! -bar -bang -buffer -nargs=? -complete=custom,s:Complete' command
          \ 'call s:dispatch(' . string(fnamemodify(a:git_dir, ':h')) . ', ' . string(app) . ', "<bang>", <q-args>)'
  endfor
endfunction

function! s:ProjectionistDetect() abort
  let root = expand('~/.heroku/plugins/')
  let file = get(g:, 'projectionist_file', get(b:, 'projectionist_file', ''))
  if strpart(file, 0, len(root)) ==# root
    call projectionist#append(root . matchstr(file, '[^/]\+', len(root)), {
          \ "*": {"path": ["lib"]},
          \ "lib/heroku/command/*.rb": {"command": "command", "template": [
          \   "#",
          \   "class Heroku::Command::{capitalize|camelcase} < Heroku::Command::Base",
          \   "",
          \   "  # {hyphenate}",
          \   "  #",
          \   "  #",
          \   "  def index",
          \   "  end",
          \   "",
          \   "end"
          \ ]}})
  endif
endfunction

augroup heroku
  autocmd!
  autocmd BufNewFile,BufReadPost *
        \ if !exists('g:loaded_fugitive') |
        \   call s:Detect(finddir('.git', '.;')) |
        \ endif
  autocmd User Fugitive call s:Detect(b:git_dir)
  autocmd User ProjectionistDetect call s:ProjectionistDetect()
augroup END

command! -bar -bang -nargs=? -complete=custom,s:Complete
      \ Hk     call s:dispatch(getcwd(), '', '<bang>', <q-args>)

command! -bar -bang -nargs=? -complete=custom,s:Complete
      \ Heroku call s:dispatch(getcwd(), '', '<bang>', <q-args>)
