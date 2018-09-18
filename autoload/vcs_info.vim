"" vcs_info

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
  let base = fnamemodify(resolve(expand('%:p')), ':h')
  let [name, root] = s:detect_vcs(base)
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

function! s:define_execute() abort
  if has('job')
    let s:job = {}
    function! s:job.callback(ch, msg) abort
      let self.output += [a:msg]
    endfunction
    function! s:job.close_cb(ch) abort
      let self.closed = 1
    endfunction
    function! s:execute(cmd) abort
      let job = extend(copy(s:job), {'output': [], 'closed': 0})
      let job.handle = job_start(a:cmd, {
            \ 'out_mode': 'raw',
            \ 'err_mode': 'raw',
            \ 'callback': job.callback,
            \ 'close_cb': job.close_cb,
            \ })
      while job.closed == 0 || job_status(job.handle) !=# 'dead'
        sleep 10m
      endwhile
      return job_info(job.handle).exitval == 0 ? join(job.output, '') : ''
    endfunction
  else
    function! s:execute(cmd) abort
      if type(a:cmd) == type([])
        let cmd = join(map(copy(a:cmd), 'escape(v:val, " ")'), ' ')
      else
        let cmd = a:cmd
      endif
      let result = system(cmd)
      return v:shell_error == 0 ? result : ''
    endfunction
  endif
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

call s:define_execute()

call s:load_vcs_info(expand('<sfile>:p:r'))
