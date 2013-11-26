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

function! s:filepath()
  return fnamemodify(expand('%'), ':p')
endfunction

function! vcs_info#find_root()
  let vcs_info_cache = s:get_vcs_info()
  return !empty(vcs_info_cache)
        \ ? [vcs_info_cache.name, vcs_info_cache.root]
        \ : ['', '']
endfunction

function! vcs_info#get_branch()
  let vcs_info_cache = s:get_vcs_info()
  return !empty(vcs_info_cache)
        \ ? [vcs_info_cache.name, vcs_info_cache.branch]
        \ : ['', '']
endfunction

function! vcs_info#get_status()
  let vcs_info_cache = s:get_vcs_info()
  return !empty(vcs_info_cache)
        \ ? [vcs_info_cache.name, vcs_info_cache.branch, vcs_info_cache.status]
        \ : ['', '', '']
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
  let file = s:filepath()
  let bufnr = bufnr(file)
  if bufnr >= 0 && type(getbufvar(bufnr, 'vcs_info_cache')) == type({})
    return getbufvar(bufnr, 'vcs_info_cache')
  endif

  let vcs_info_cache = {}
  let [name, root] = s:detect_vcs(fnamemodify(file, ':h'))
  if name !=# ''
    let branch = s:vcs[name].branch(root)
    if branch !=# ''
      let vcs_info_cache.name = name
      let vcs_info_cache.root = root
      let vcs_info_cache.branch = substitute(branch, '[\r\n]\+$', '', '')
      let vcs_info_cache.status = s:vcs[name].status(root) 
    endif
  endif
  call setbufvar(bufnr, 'vcs_info_cache', vcs_info_cache)
  return vcs_info_cache
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
