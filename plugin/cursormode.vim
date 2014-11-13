" Copyright (C) 2014 Andrea Cedraro <a.cedraro@gmail.com>
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the "Software"),
" to deal in the Software without restriction, including without limitation
" the rights to use, copy, modify, merge, publish, distribute, sublicense,
" and/or sell copies of the Software, and to permit persons to whom the
" Software is furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included
" in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
" OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
" IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
" DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
" TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
" OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

let s:is_win = has('win32') || has('win64')
let s:is_iTerm = exists('$TERM_PROGRAM') && $TERM_PROGRAM =~# 'iTerm.app'
let s:is_AppleTerminal = exists('$TERM_PROGRAM') && $TERM_PROGRAM =~# 'Apple_Terminal'

let s:is_good = !has('gui_running') && !s:is_win && !s:is_AppleTerminal

if exists('g:loaded_cursormode') || !s:is_good
  finish
endif
let g:loaded_cursormode = 1

let s:cpo_save = &cpo
set cpo&vim

let s:last_mode = ''

let s:tmux_escape_prefix = empty('$TMUX') ? '' : '\033Ptmux;\033'
let s:iTerm_escape_template = '"%s\033]Pl%s\033\\"'
let s:xterm_escape_template = '"%s\033]12;%s\007"'

function! cursormode#CursorMode()
  let mode = mode()
  if mode !=# s:last_mode
    let s:last_mode = mode
    call s:set_cursor_color_for(mode)
  endif
  return ''
endfunction

function! s:set_cursor_color_for(mode)
  let mode = a:mode
  for mode in [a:mode, a:mode.&background]
    if has_key(s:color_map, mode)
      try
        let save_shelltemp = &shelltemp
        set noshelltemp
        noautocmd silent call system(s:build_command(s:color_map[mode]))
        return
      finally
        let &shelltemp = save_shelltemp
      endtry
    endif
  endfor
endfunction

function! s:build_command(color)
  if s:is_iTerm
    let color = substitute(a:color, '^#', '', '')
    let escape_template = s:iTerm_escape_template
  else
    let color = a:color
    let escape_template = s:xterm_escape_template
  endif

  let escape = printf(escape_template, s:tmux_escape_prefix, color)
  return printf('printf %s > /dev/tty', escape)
endfunction

function! s:get_color_map()
  if exists('g:cursormode_color_map')
    return g:cursormode_color_map
  endif

  try
    let map = g:cursormode#{g:colors_name}#color_map
    return map
  catch
    return {
          \   "nlight": "#000000",
          \   "ndark":  "#BBBBBB",
          \   "i":      "#0000BB",
          \   "v":      "#FF5555",
          \   "V":      "#BBBB00",
          \   "\<C-V>": "#BB00BB",
          \ }
  endtry
endfunction
let s:color_map = s:get_color_map()

function! cursormode#Activate()
  call s:activate('&statusline')
endfunction

function! cursormode#LocalActivate()
  call s:activate('&l:statusline')
endfunction

function! s:activate(on)
  call s:deactivate(a:on)
  execute 'let' a:on ".= '%{cursormode#CursorMode()}'"

  call s:setup_autocmds()
endfunction

function! s:deactivate(on)
  execute 'let' a:on "= substitute(".a:on.", '%{cursormode#CursorMode()}', '', 'g')"
endfunction

function! s:setup_autocmds()
  augroup cursormode
    autocmd!
    autocmd VimLeave * call s:set_cursor_color_for("n")
    autocmd Colorscheme * let s:color_map = s:get_color_map()
  augroup END
endfunction

call cursormode#Activate()

let &cpo = s:cpo_save
unlet s:cpo_save
