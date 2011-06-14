" cakephp.vim 
" A vim toolset for navigating and managing CakePHP projects
" Version: 1.0
" Author: Nick Reynolds
" Repository: http://github.com/ndreynolds/vim-cakephp
" License: Public Domain

if exists("g:loaded_vim-cake") || &cp
    finish
endif

let g:loaded_cake = '1.0'
let s:cpo_save = &cpo
set cpo&vim

function! s:openController(...)
    " Open the associated or specified controller
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            let controllers_root = fnamemodify(associations.controller,':h')
            let path = controllers_root . '/' . s:matchController(s:baseName(a:1)) . '.php'
            call s:openPath(path)
        else
            call s:openPath(associations.controller)
        endif
    endif
endfunction

function! s:openModel(...)
    " Open the related or specified model
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            let models_root = fnamemodify(associations.model,':h')
            let path = models_root . '/' . s:baseName(a:1) . '.php'
            call s:openPath(path)
        else
            let associations = s:associate()
            call s:openPath(associations.model)
        endif
    endif
endfunction

function! s:openView(...)
    " Open a file browser in the related view directory, or the specified view
    " within it.
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            let path = associations.views_direc . '/' . a:1 . '.ctp'
            call s:openPath(path)
        else
            call s:openPath(associations.views_direc)
        endif
    endif
endfunction

function! s:openPath(path, ...)
    " Utility function that opens a given path as a buffer. Allows specifying
    " window type (i.e. split, vsplit, etc.)
    exec 'split ' . a:path
endfunction

function! s:associate()
    " Utility function that builds and returns a dictionary of filenames that 
    " represent the associated elements in the MVC entity--based on the 
    " filename of the buffer that the script's methods are called from.
    let path = expand('%:p')
    let name = remove(split(expand('%:r'),'/'),-1) " Get filename from rel or abs path
    let ext = expand('%:e')
    let parent = expand('%:p:h:t')
    let parent_path = expand('%:p:h')
    let grandparent = expand('%:p:h:h:t')
    let grandparent_path = expand('%:p:h:h')
    let ggrandparent_path = expand('%:p:h:h:h')
    if parent == 'controllers'
        let base_name = s:baseName(name)
        let app_root = grandparent_path
    elseif parent == 'models'
        let base_name = s:baseName(name)
        let app_root = grandparent_path
    elseif grandparent == 'views'
        let base_name = s:baseName(parent)
        let app_root = ggrandparent_path
    else
        echo 'cake.vim: Unable to find a CakePHP app. Call inside a model, controller, or view' 
        return {}
    endif
    let app_root = app_root . "/"
    let associations = {}
    let associations.controller = app_root . 'controllers/' . s:matchController(base_name) . '.php'
    let associations.model = app_root . 'models/' . base_name . '.php'
    let associations.views_direc = app_root . 'views/' . s:matchViewDirec(base_name)
    let associations.views = split(glob(associations.views_direc . "/*"),"\n")
    return associations
endfunction

function! s:baseName(name)
    " Returns the lowercase, singular form of the MVC entity.
    " Ex. posts, post, posts_controller => post
    let name = a:name
    if len(split(name,'_')) > 1 " Check if it is a controller
        return s:singularize(split(name,'_')[0])
    elseif s:isPlural(name)
        return s:singularize(name)
    else
        return name
    endif
endfunction

function! s:sub(str,pat,rep)
    return substitute(a:str, '\v\C'.a:pat, a:rep, '')
endfunction

function! s:singularize(word)
    " Singularize an (english) word. Borrowed from github.com/tpope/vim-rails
    " Ex. boxes => box
    let word = a:word
    if word =~? '\.js$' || word == ''
        return word
    endif
    let word = s:sub(word,'eople$','ersons')
    let word = s:sub(word,'%([Mm]ov|[aeio])@<!ies$','ys')
    let word = s:sub(word,'xe[ns]$','xs')
    let word = s:sub(word,'ves$','fs')
    let word = s:sub(word,'ss%(es)=$','sss')
    let word = s:sub(word,'s$','')
    let word = s:sub(word,'%([nrt]ch|tatus|lias)\zse$','')
    let word = s:sub(word,'%(nd|rt)\zsice$','ex')
    return word
endfunction

function! s:pluralize(word)
    " Pluralize an (english) word. Borrowed from github.com/tpope/vim-rails
    " Ex. box => boxes
    let word = a:word
    if word == ''
        return word
    endif
    let word = s:sub(word,'[aeio]@<!y$','ie')
    let word = s:sub(word,'%(nd|rt)@<=ex$','ice')
    let word = s:sub(word,'%([osxz]|[cs]h)$','&e')
    let word = s:sub(word,'f@<!f$','ve')
    let word .= 's'
    let word = s:sub(word,'ersons$','eople')
    return word
endfunction

function! s:isSingular(word)
    " Check if a word is singular, not definitive.
    " The idea: pluralize the parameter and singularize the result, if that
    " result is the same as the parameter, it's probably singular.
    return s:singularize(s:pluralize(a:word)) == a:word
endfunction

function! s:isPlural(word)
    " Check if a word is plural, not definitive.
    return s:pluralize(s:singularize(a:word)) == a:word
endfunction

function! s:matchController(base_name)
    " Get the controller's filename based on the return from baseName()
    return s:pluralize(a:base_name) . '_controller'
endfunction

function! s:matchViewDirec(base_name)
    " Get the view directory's name based on the return from baseName()
    return s:pluralize(a:base_name)
endfunction

command! -n=? Ccontroller call s:openController(<f-args>)
command! -n=? Cmodel call s:openModel(<f-args>)
command! -n=? Cview call s:openView(<f-args>)
command! -n=0 Cassoc echo s:associate()
