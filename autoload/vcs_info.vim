"" vcs_info

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

let s:vcs = {}

function! s:load_vcs_info(this_file)
  for name in map(split(glob(a:this_file . '/*.vim'),
        \ "\n"), 'fnamemodify(v:val, ":t:r")')
    let s:vcs[name] = vcs_info#{name}#load()
  endfor

  augroup vcs-info-cache
    autocmd!
    autocmd BufLeave * call vcs_info#clear_cache()
  augroup END
endfunction

call s:load_vcs_info(expand('<sfile>:p:r'))

function! vcs_info#find_root()
  let vcs_info_cache = s:get_vcs_info()
  return !empty(vcs_info_cache)
        \ ? [vcs_info_cache.name, vcs_info_cache.root]
        \ : ['', '']
endfunction

function! vcs_info#get_branch()
  let vcs_info_cache = s:get_vcs_info()
  if empty(vcs_info_cache)
    return ['', '']
  endif
  let name = vcs_info_cache.name
  let root = vcs_info_cache.root
  return [name, s:get_vcs_branch(name, root)]
endfunction

function! vcs_info#get_status()
  let vcs_info_cache = s:get_vcs_info()
  if empty(vcs_info_cache)
    return ['', '', '']
  endif
  let name = vcs_info_cache.name
  let root = vcs_info_cache.root
  return [name, s:get_vcs_branch(name, root), s:get_vcs_status(name, root)]
endfunction

function! vcs_info#clear_cache()
  if exists('b:vcs_info_cache')
    unlet b:vcs_info_cache
  endif
endfunction

function! s:detect_vcs(base)
  let info = {}
  for name in keys(s:vcs)
    if s:vcs[name].exists
      let root = s:vcs[name].root(a:base)
      let info[len(root)] = [name, root]
    endif
  endfor
  let info[0] = ['', '']
  return info[max(keys(info))]
endfunction

function! s:get_vcs_info()
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

function! s:get_vcs_branch(name, root)
  if exists('b:vcs_info_cache.branch')
    return b:vcs_info_cache.branch
  endif
  let branch = s:vcs[a:name].branch(a:root)
  let b:vcs_info_cache.branch = branch
  return branch
endfunction

function! s:get_vcs_status(name, root)
  if exists('b:vcs_info_cache.status')
    return b:vcs_info_cache.status
  endif
  let status = s:vcs[a:name].status(a:root)
  let b:vcs_info_cache.status = status
  return status
endfunction

function! s:check_vimproc()
  try
    call vimproc#version()
    function! s:execute(cmd)
      let result = vimproc#system(a:cmd)
      return vimproc#get_last_errmsg() ==# '' ? result : ''
    endfunction
  catch
    function! s:execute(cmd)
      let result = system(join(map(copy(a:cmd), 'escape(v:val, " ")'), ' '))
      return v:shell_error != 0 ? result : ''
    endfunction
  endtry
endfunction

call s:check_vimproc()

function! vcs_info#execute(cmds)
  for cmd in a:cmds
    let result = s:execute(cmd)
    if result !=# ''
      return result
    endif
  endfor
  return ''
endfunction

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
