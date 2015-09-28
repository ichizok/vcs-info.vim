"" vcs_info

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

let s:vcs = {}

function! s:load_vcs_info(this_file) abort
  for name in map(split(glob(a:this_file . '/*.vim'),
        \ "\n"), 'fnamemodify(v:val, ":t:r")')
    if executable(name)
      let s:vcs[name] = vcs_info#{name}#load()
    endif
  endfor

  augroup vcs-info-cache
    autocmd!
    autocmd BufLeave * call vcs_info#clear_cache()
  augroup END
endfunction

function! vcs_info#find_root() abort
  let vcs_info_cache = s:get_vcs_info()
  return !empty(vcs_info_cache)
        \ ? [vcs_info_cache.name, vcs_info_cache.root]
        \ : ['', '']
endfunction

function! vcs_info#get_branch() abort
  let vcs_info_cache = s:get_vcs_info()
  if empty(vcs_info_cache)
    return ['', '']
  endif
  let name = vcs_info_cache.name
  let root = vcs_info_cache.root
  return [name, s:get_vcs_branch(name, root)]
endfunction

function! vcs_info#get_status() abort
  let vcs_info_cache = s:get_vcs_info()
  if empty(vcs_info_cache)
    return ['', '', '']
  endif
  let name = vcs_info_cache.name
  let root = vcs_info_cache.root
  return [name, s:get_vcs_branch(name, root), s:get_vcs_status(name, root)]
endfunction

function! vcs_info#clear_cache() abort
  if exists('b:vcs_info_cache')
    unlet b:vcs_info_cache
  endif
endfunction

function! s:detect_vcs(base) abort
  let info = {}
  for name in keys(s:vcs)
    try
      let root = s:vcs[name].root(a:base)
      let info[len(root)] = [name, root]
    catch
      " nop
    endtry
  endfor
  let info[0] = ['', '']
  return info[max(keys(info))]
endfunction

function! s:get_vcs_info() abort
  if exists('b:vcs_info_cache') && type(b:vcs_info_cache) == type({})
    return b:vcs_info_cache
  endif

  let vcs_info_cache = {}
  let [name, root] = s:detect_vcs(expand('%:p:h'))
  if name !=# ''
    let vcs_info_cache.name = name
    let vcs_info_cache.root = root
  endif
  let b:vcs_info_cache = vcs_info_cache
  return vcs_info_cache
endfunction

function! s:get_vcs_branch(name, root) abort
  if exists('b:vcs_info_cache.branch')
    return b:vcs_info_cache.branch
  endif
  try
    let branch = s:vcs[a:name].branch(a:root)
  catch
    let branch = ''
  endtry
  let b:vcs_info_cache.branch = branch
  return branch
endfunction

function! s:get_vcs_status(name, root) abort
  if exists('b:vcs_info_cache.status')
    return b:vcs_info_cache.status
  endif
  try
    let status = s:vcs[a:name].status(a:root)
  catch
    let status = ''
  endtry
  let b:vcs_info_cache.status = status
  return status
endfunction

function! s:check_vimproc() abort
  try
    call vimproc#version()
    function! s:execute(cmd) abort
      let result = vimproc#system(a:cmd)
      return vimproc#get_last_status() == 0 ? result : ''
    endfunction
  catch
    function! s:execute(cmd) abort
      let result = system(join(map(copy(a:cmd), 'escape(v:val, " ")'), ' '))
      return v:shell_error == 0 ? result : ''
    endfunction
  endtry
endfunction

function! vcs_info#execute(cmds) abort
  for cmd in a:cmds
    let result = substitute(s:execute(cmd), '[\r\n]\+$', '', '')
    if result !=# ''
      return result
    endif
  endfor
  return ''
endfunction

call s:check_vimproc()

call s:load_vcs_info(expand('<sfile>:p:r'))

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
