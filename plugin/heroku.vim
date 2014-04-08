" Location:     plugin/heroku.vim
" Maintainer:   Tim Pope <code@tpope.net>
" Version:      1.0

if exists("g:loaded_heroku") || v:version < 700 || &cp
  finish
endif
let g:loaded_heroku = 1

function! s:hk_plugins() abort
  let env = empty($HKPATH) ? '/usr/local/lib/hk/plugin' : $HKPATH
  let path = escape(join(split(env, has('win32') ? ';' : ':'), ','), ' ')
  return map(filter(split(globpath(path, '*')), 'executable(v:val)'), 'fnamemodify(v:val, ":t")')
endfunction

function! s:hk_has_plugin(plugin) abort
  return index(s:hk_plugins(), a:plugin) >= 0
endfunction

function! s:hk_system(args) abort
  if !executable('hk')
    return []
  endif
  let output = system('hk '.a:args)
  if v:shell_error
    throw substitute(output, "\n$", '', '')
  else
    return split(output, "\n")
  endif
endfunction

function! s:prepare(args, app) abort
  let args = a:args
  let command = matchstr(args, '\a\S*')
  if !empty(command) && args !~# '^\a\S*\s\+-a' && !empty(a:app)
        \ && s:usage(command) =~# '-a <app>'
    let args = substitute(args, '\S\@<=\S\@!', ' -a '.a:app, '')
  endif
  if executable('hk')
    if empty(command) || has_key(s:hk_commands(), command) || s:hk_has_plugin(command) || s:hk_has_plugin('default')
      return 'hk ' . args
    endif
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
    let &mp = s:prepare(a:args, a:app)
    if a:args =~# '^\s*\%(run\|console\)\>:\@!' && substitute(a:args, '-- .*', '', '') !~# ' -d\>'
      execute cd '~'
      let title = empty(a:app) ? 'heroku' : a:app
      let title .= ' '.matchstr(a:args, '^\s*\%(run\s\+\)\=\%(-a\s\+\S\+\s\+\)\=\zs\S\+')
      if exists(':Start')
        execute 'Start'.a:bang '-title='.escape(title, ' ') &mp
      else
        execute '!'.&mp
      endif
    else
      let b:current_compiler = 'heroku'
      let &l:efm = '%+G%.%#'
      execute cd fnameescape(a:dir)
      execute (exists(':Make') == 2 ? 'Make' : 'make').a:bang
    endif
  finally
    let [&l:mp, &l:efm, b:current_compiler] = [mp, efm, cc]
    if empty(cc) | unlet! b:current_compiler | endif
    execute cd fnameescape(cwd)
  endtry
endfunction

unlet! s:hk_commands
function! s:hk_commands() abort
  if !exists('s:hk_commands')
    let s:hk_commands = {}
    for line in s:hk_system('help commands')
      let command = matchstr(line, '^hk \zs\S\+')
      if !empty(command)
        let s:hk_commands[command] = matchstr(line, '^hk \S\+ \zs.\{-\}\ze\s*#')
      endif
    endfor
    lockvar s:hk_commands
  endif
  return s:hk_commands
endfunction

let s:usage = {}
function! s:usage(command) abort
  if empty(a:command)
    return ''
  elseif a:command ==# 'run'
    return '[-a <app>] ' . get(s:hk_commands(), 'run', '[-s <size>] [-d] <command> [<argument>...]')
  elseif has_key(s:hk_commands(), a:command)
    return s:hk_commands[a:command]
  endif
  if !has_key(s:usage, a:command)
    let usage = matchstr(
          \ system('hk help '.a:command),
          \ 'Usage:\s*\S\+ \+[[:alnum:]:-]\+ \+\zs'."[^\n]*")
    let s:usage[a:command] = empty(usage) ? '[-a <app>]' : usage
  endif
  return s:usage[a:command]
endfunction

function! Heroku_app_list(...) abort
  return map(s:hk_system('apps'), 'matchstr(v:val, "^\\S*")')
endfunction

function! Heroku_dbname_list(app, ...) abort
  if !empty(a:app)
    return map(s:hk_system('pg-list -a '.a:app), 'matchstr(v:val, "\\w\\S*")')
  endif
  return []
endfunction

function! Heroku_feature_list(app, cmd) abort
  if a:cmd =~# '^account'
    return map(s:hk_system('account-features'), 'matchstr(v:val, "\\w\\S*")')
  elseif !empty(a:app)
    return map(s:hk_system('features -a '.a:app), 'matchstr(v:val, "\\w\\S*")')
  endif
  return []
endfunction

function! Heroku_name_list(app, cmd) abort
  if a:cmd !~# '[gs]et'
    return Heroku_app_list()
  elseif !empty(a:app)
    return map(s:hk_system('releases -a '.a:app), 'matchstr(v:val, "^\\S\\+")')
  endif
endfunction

function! Heroku_region_list(...) abort
  return map(s:hk_system('regions'), 'matchstr(v:val, "^\\S*")')
endfunction

function! Heroku_service_list(...) abort
  return s:hk_system('addon-services')
endfunction

function! Heroku_version_list(app, ...) abort
  if !empty(a:app)
    return map(s:hk_system('releases -a '.a:app), 'matchstr(v:val, "^\\S\\+")')
  endif
endfunction

function! s:complete_usage(cmd, A, L, P) abort
  let usage = s:usage(a:cmd)
  let opt = matchstr(strpart(a:L, 0, a:P), ' \zs-[a-z]\ze \+\S*$')
  let type = matchstr(usage, '\['.opt.' <\zs[^<>]*\ze>')
  if exists('*Heroku_'.type.'_list')
    return Heroku_{type}_list(s:complete_app, a:cmd)
  elseif !empty(type)
    return []
  endif
  let options = split(substitute(usage, '<[^<>]*>\|[][.:]', '', 'g'), '\s\+')
  let args = split(substitute(usage, '\[-[^[]*\]\|[][.]', '', 'g'), '[[:space:]:]\+')
  let g:args = args
  if exists('*Heroku_'.get(args, 0, '')[1:-2].'_list')
    return Heroku_{args[0][1:-2]}_list(s:complete_app, a:cmd) + options
  endif
  return options
endfunction

function! s:completion_filter(results, A) abort
  return join(a:results, "\n")
endfunction

function! s:Complete(A, L, P) abort
  let s:complete_app = matchstr(a:L, ' -a \zs\S\+')
  if empty(s:complete_app)
    silent! execute matchstr(a:L, '\u\a*') '&'
  endif
  let cmd = matchstr(strpart(a:L, 0, a:P), '[! ]\zs\(\S\+\)\ze\s\+')
  if !empty(cmd)
    return s:completion_filter(filter(s:complete_usage(cmd, a:A, a:L, a:P), 'v:val !=# "-a"'), a:A)
  endif
  return s:completion_filter(sort(filter(keys(s:hk_commands()) + s:hk_plugins(), 'v:val !=# "default"')), a:A)
endfunction

function! s:GlobalComplete(A, L, P) abort
  let s:complete_app = matchstr(a:L, ' -a \zs\S\+')
  let cmd = matchstr(strpart(a:L, 0, a:P), '[! ]\zs\(\S\+\)\ze\s\+')
  if !empty(cmd)
    return s:completion_filter(s:complete_usage(cmd, a:A, a:L, a:P), a:A)
  endif
  return s:completion_filter(sort(filter(keys(s:hk_commands()) + s:hk_plugins(), 'v:val !=# "default"')), a:A)
endfunction

function! s:Detect(git_dir) abort
  let remotes = {}
  if filereadable(a:git_dir.'/config')
    for line in readfile(a:git_dir.'/config')
      let remote = matchstr(line, '^\s*\[\s*remote\s\+"\zs.*\ze"\s*\]\s*$')
      if !empty(remote)
        let alias = remote
      endif
      let app = matchstr(line, '^\s*url\s*=.*heroku.com:\zs.*\ze\.git\s*$')
      if !empty(app)
        let remotes[alias] = app
      endif
    endfor
  endif
  for [remote, app] in items(remotes)
    let command = substitute(remote, '\%(^\|[-_]\+\)\(\w\)', '\u\1', 'g')
    execute 'command! -bar -bang -buffer -nargs=? -complete=custom,s:Complete' command
          \ 'call s:dispatch(' . string(fnamemodify(a:git_dir, ':h')) . ', ' . string(app) . ', "<bang>", <q-args>)'
  endfor
endfunction

augroup heroku
  autocmd!
  autocmd BufNewFile,BufReadPost *
        \ if !exists('g:loaded_fugitive') |
        \   call s:Detect(finddir('.git', '.;')) |
        \ endif
  autocmd User Fugitive call s:Detect(b:git_dir)
augroup END

command! -bar -bang -nargs=? -complete=custom,s:GlobalComplete
      \ Hk     call s:dispatch(getcwd(), '', '<bang>', <q-args>)

command! -bar -bang -nargs=? -complete=custom,s:GlobalComplete
      \ Heroku call s:dispatch(getcwd(), '', '<bang>', <q-args>)
