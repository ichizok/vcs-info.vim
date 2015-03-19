"" vcs_info#git

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

let s:vcs_git = {
      \   'exists' : executable('git'),
      \ }

function! s:abspath(path, mods) abort
  return a:path !=# '' ? fnamemodify(a:path, a:mods) : ''
endfunction

function! s:vcs_git.root(base) abort
  let dir = s:abspath(finddir('.git', a:base . ';'), ':p:h:h')
  let file = s:abspath(findfile('.git', a:base . ';'), ':p:h')
  return len(dir) >= len(file) ? dir : file
endfunction

function! s:vcs_git.branch(path) abort
  let dotgit = a:path . '/.git'
  if filereadable(dotgit)
    let line = readfile(dotgit)[0]
    let gitdir = matchstr(line, '^gitdir:\s*\zs.*')
    if gitdir !=? fnamemodify(gitdir, ':p:h')
      let gitdir = a:path . '/' . gitdir
    endif
  else
    let gitdir = dotgit
  endif
  if isdirectory(gitdir) && filereadable(gitdir . '/HEAD')
    let line = readfile(gitdir . '/HEAD')[0]
    if line =~# 'refs/heads/'
      return matchstr(line, 'refs/heads/\zs.*')
    else
      return line[: 6]
    endif
  endif
  return ''
endfunction

function! s:vcs_git.status(path) abort
  execute 'lcd' a:path
  let output = vcs_info#execute([
        \   ['git', 'status', '--short'],
        \ ])
  lcd -
  return output
endfunction

function! vcs_info#git#load() abort
  return copy(s:vcs_git)
endfunction

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
