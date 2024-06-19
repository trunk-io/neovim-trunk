if exists('g:loaded_trunk') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

function! OpenConfig()
  let configFile = v:lua.require'trunk'.findConfig()
  execute 'edit '.fnameescape(configFile)
endfunction

" command to open trunk.yaml
command! TrunkConfig :call OpenConfig()

" command to render any errors
command! TrunkStatus lua require'trunk'.printStatus()

" command to render actions and pickers
command! TrunkActions lua require'trunk'.actions()

" command to list all applicable linters for a file
command! TrunkQuery lua require'trunk'.checkQuery()

" command to list all applicable linters for a file
command! TrunkLogs lua require'trunk'.openLogs()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_trunk = 1