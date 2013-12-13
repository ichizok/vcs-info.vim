"" vcs_info#hg

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

let s:vcs_hg = {
      \   'exists' : executable('hg'),
      \ }

function! s:vcs_hg.root(base) 
  let root = finddir('.hg', a:base . ';')
  return root !=# '' ? fnamemodify(root, ':p:h:h') : ''
endfunction

if has('python') && !get(g:, 'vcs_info#hg#disable_if_python', 0)
  function! s:vcs_hg.branch(path) 
    let branch = ''
    python <<EOT
if not 'vcs_info_hg_branch' in globals():
    import mercurial.hg
    import mercurial.ui
    import vim
    def vcs_info_hg_branch():
        try:
            repo = mercurial.hg.repository(mercurial.ui.ui(), vim.eval('a:path'))
            ctx = repo.changectx(".")
            vim.command('let branch = "{0}"'.format(ctx.branch()))
        except:
            pass
vcs_info_hg_branch()
EOT
    return branch
  endfunction

  function! s:vcs_hg.status(path) 
    let status = ''
    python <<EOT
if not 'vcs_info_hg_status' in globals():
    import mercurial.hg
    import mercurial.ui
    import vim
    def vcs_info_hg_status():
        try:
            repo = mercurial.hg.repository(mercurial.ui.ui(), vim.eval('a:path'))
            stat = repo.status()
            lst = []
            lst.extend('M ' + x for x in stat[0])
            lst.extend('A ' + x for x in stat[1])
            lst.extend('R ' + x for x in stat[2])
            lst.extend('! ' + x for x in stat[3])
            lst.extend('? ' + x for x in stat[4])
            lst.extend('I ' + x for x in stat[5])
            lst.extend('C ' + x for x in stat[6])
            vim.command('let status = "{0}"'.format("\n".join(lst)))
        except:
            pass
vcs_info_hg_status()
EOT
    return status
  endfunction
else
  function! s:vcs_hg.branch(path) 
    return vcs_info#execute([
      \   ['hg', '-R', a:path, 'branch']
      \ ])
  endfunction

  function! s:vcs_hg.status(path) 
    return vcs_info#execute([
      \   ['hg', '-R', a:path, 'status']
      \ ])
  endfunction
endif

function! vcs_info#hg#load()
  return copy(s:vcs_hg)
endfunction

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

