"=============================================================================="
" URL:         https://github.com/mhinz/vim-tmuxify
" Author:      Marco Hinz <mhinz@spline.de>
" Maintainer:  Marco Hinz <mhinz@spline.de>
"=============================================================================="
"
" The following functions and variables can be used by other plugins.
"
" Functions:
"
"   tmuxify#complete_panes()
"   tmuxify#complete_sessions
"   tmuxify#complete_windows()
"   tmuxify#pane_create()
"   tmuxify#pane_kill()
"   tmuxify#pane_run()
"   tmuxify#pane_send()
"   tmuxify#pane_set()
"
" Variables:
"
"   g:loaded_tmuxify
"   g:tmuxify_default_send_action
"   g:tmuxify_default_start_program
"   g:tmuxify_split_win_size
"   g:tmuxify_vert_split
"
"=============================================================================="

" loaded? {{{1
if exists('g:loaded_tmuxify') || &cp
  finish
endif
let g:loaded_tmuxify = 1

let b:tmuxified = 0

" complete_sessions() {{{1
function! tmuxify#complete_sessions(A, L, P)
  return system('tmux list-sessions | cut -d: -f1')
endfunction

" complete_windows() {{{1
function! tmuxify#complete_windows(A, L, P)
  return system('tmux list-windows -t ' . b:sessions . ' | cut -d: -f1')
endfunction

" complete_panes() {{{1
function! tmuxify#complete_panes(A, L, P)
  return system('tmux list-panes -t ' . b:sessions . ':' . b:windows .
        \' | cut -d: -f1')
endfunction

" pane_create() {{{1
function! tmuxify#pane_create(...) abort
  if !exists('$TMUX')
    echo "tmuxify: This Vim is not running in a tmux session!"
    return
  endif

  call system("tmux split-window -d " . g:tmuxify_vert_split . " -l " .
        \ g:tmuxify_split_win_size)

  let b:target_pane = str2nr(system('tmux list-panes | tail -n1 | cut -d: -f1'))
  let b:tmuxified   = 1

  if exists('a:1')
    call tmuxify#pane_send(a:1)
  endif

  augroup tmuxify
    autocmd!
    autocmd VimLeave * call tmuxify#pane_kill()
  augroup END
endfunction

" pane_kill() {{{1
function! tmuxify#pane_kill() abort
  if b:tmuxified == 0
    return
  endif

  call system('tmux kill-pane -t ' . b:target_pane)
  unlet b:target_pane
  let b:tmuxified = 0

  autocmd! tmuxify VimLeave *
  augroup! tmuxify
endfunction

" pane_run() {{{1
function! tmuxify#pane_run(path)
  if b:tmuxified == 1
    call tmuxify#pane_kill()
  endif

  call tmuxify#pane_create()
  call tmuxify#pane_send('clear; ' .
        \ g:tmuxify_default_start_program .
        \ ' ' .
        \ a:path .
        \ '; ' .
        \ g:tmuxify_default_start_program)
endfunction

" pane_send() {{{1
function! tmuxify#pane_send(...) abort
  if b:tmuxified == 0
    return
  endif

  if exists('a:1')
    let l:action = a:1
  else
    if exists('g:tmuxify_default_send_action')
      let l:action = g:tmuxify_default_send_action
    else
      let l:action = input('tmuxify> ')
    endif
  endif

  call system("tmux send-keys -t " . b:target_pane . " '" . l:action . "' C-m")
endfunction

" pane_set() {{{1
function! tmuxify#pane_set()
  if !exists('$TMUX')
    echo "tmuxify: This Vim is not running in a tmux session!"
    return
  endif

  let b:sessions    = input('Session: ', '', 'custom,tmuxify#complete_sessions')
  let b:windows     = input('Window: ', '', 'custom,tmuxify#complete_windows')
  let b:panes       = input('Pane: ', '', 'custom,tmuxify#complete_panes')
  let b:target_pane = b:sessions . ':' .  b:windows . '.' . b:panes
endfunction

" vim: et sw=2 sts=2 tw=80