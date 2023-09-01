if exists('g:loaded_trunk') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

function! OpenConfig()
  let configFile = v:lua.require'trunk'.findConfig()
  execute 'edit '.fnameescape(configFile)
endfunction

" command to run our plugin
lua require'trunk'.start()

" command to open trunk.yaml
command! TrunkConfig :call OpenConfig()

" command to render any errors
command! TrunkStatus lua require'trunk'.printStatus()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_trunk = 1