" cakephp.vim
" A vim plugin for navigating and managing CakePHP projects
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

" Set the operating system type and directory separator constant
let s:DS = '/'
if has('unix') && strpart(system('uname'),0,6) == 'Darwin'
    let s:OS = 'mac'
elseif has('unix')
    let s:OS = 'unix'
elseif has('win32')
    let s:OS = 'windows'
    let s:DS = '\'
else
    let s:OS = 'unknown'
endif

function! s:openController(method, ...)
    " Open the associated or specified controller
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            let controllers_root = fnamemodify(associations.controller,':h')
            let path = controllers_root . s:DS . s:matchController(s:baseName(a:1)) . '.php'
            call s:openWindow(path, a:method)
        else
            call s:openWindow(associations.controller, a:method)
        endif
    endif
endfunction

function! s:openModel(method, ...)
    " Open the related or specified model
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            let models_root = fnamemodify(associations.model,':h')
            let path = models_root . s:DS . s:baseName(a:1) . '.php'
            call s:openWindow(path, a:method)
        else
            let associations = s:associate()
            call s:openWindow(associations.model, a:method)
        endif
    endif
endfunction

function! s:openView(method, ...)
    " Open a file browser in the related view directory, or the specified view
    " within it.
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            if len(split(a:1,s:DS)) > 1
                let controller = split(a:1,s:DS)[0]
                let view = split(a:1,s:DS)[1]
                let path = associations.app . s:DS . 'views' . s:DS . s:matchViews(s:baseName(controller)) . s:DS . view . '.ctp'
            else
                let path = associations.views . s:DS . a:1 . '.ctp'
            endif
            call s:openWindow(path, a:method)
        else
            call s:openWindow(associations.views, a:method)
        endif
    endif
endfunction

function! s:openFile(extension, method, ...)
    " Open static files like js or css, provided their path is in
    " associations.
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            let path = associations[a:extension] . s:DS . a:1 . '.' . a:extension
            call s:openWindow(path, a:method)
        else
            call s:openWindow(associations[a:extension], a:method)
        endif
    endif
endfunction

function! s:openWindow(path, method)
    " Utility function that opens a given path as in the window using the 
    " provided method.
    exec a:method . ' ' . a:path
endfunction

function! s:associate()
    " Utility function that builds and returns a dictionary of filenames that 
    " represent the associated elements in the MVC entity--based on the 
    " filename of the buffer that the script's methods are called from.
    let path = expand('%:p')
    let name = remove(split(expand('%:r'),s:DS),-1) " Get filename from rel or abs path
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
        echo 'cakephp.vim - Warning: Unable to find a CakePHP app. Call inside a model, controller, or view.' 
        return {}
    endif
    let associations = {}
    let associations.app         = app_root
    let associations.controller  = app_root . s:DS . 'controllers' . s:DS . s:matchController(base_name) . '.php'
    let associations.model       = app_root . s:DS . 'models' . s:DS . base_name . '.php'
    let associations.views       = app_root . s:DS . 'views' . s:DS . s:matchViews(base_name)
    let associations.css         = app_root . s:DS . 'webroot' . s:DS . 'css'
    let associations.js          = app_root . s:DS . 'webroot' . s:DS . 'js'
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

function! s:matchViews(base_name)
    " Get the view directory's name based on the return from baseName()
    return s:pluralize(a:base_name)
endfunction

function! s:openDoc(...)
    " Open the Cake API documentation in a browser using the shell's 'open' command, 
    " takes an optional query string to open search results.
    let url = 'http://api.cakephp.org/'
    if a:0 > 0
        let url .= 'search/' . join(split(a:1),'\%20')
    endif
    if s:OS == 'mac' || s:OS == 'windows'
        " To avoide any 'ENTER to continue' nonsense, we need to run the
        " command silently, followed by a window redraw, just in case.
        exec 'silent ! open ' . url . ' &'
        exec 'redraw!' 
    elseif s:OS == 'unix' 
        " This is really just a best guess, there's no standard *nix command that
        " achieves the equivalent of 'open' on Mac/Windows.
        exec 'silent ! gnome-open ' . url . ' &'
        exec 'redraw!'
    else
        echo "cakephp.vim - Error: Couldn't recognize your Operating System."
    endif
endfunction

command! -n=? Ccontroller call s:openController('edit', <f-args>)
command! -n=? CVcontroller call s:openController('vsplit', <f-args>)
command! -n=? CScontroller call s:openController('split', <f-args>)
command! -n=? Cmodel call s:openModel('edit', <f-args>)
command! -n=? CVmodel call s:openModel('vsplit', <f-args>)
command! -n=? CSmodel call s:openModel('split', <f-args>)
command! -n=? Cview call s:openView('edit', <f-args>)
command! -n=? CVview call s:openView('vsplit', <f-args>)
command! -n=? CSview call s:openView('split', <f-args>)
command! -n=? Ccss call s:openFile('css', 'edit', <f-args>)
command! -n=? CVcss call s:openFile('css', 'vsplit', <f-args>)
command! -n=? CScss call s:openFile('css', 'split', <f-args>)
command! -n=? Cjs call s:openFile('js', 'edit', <f-args>)
command! -n=? CVjs call s:openFile('js', 'vsplit', <f-args>)
command! -n=? CSjs call s:openFile('js', 'split', <f-args>)
command! -n=0 Cassoc echo s:associate()
command! -n=? Cdoc call s:openDoc(<f-args>)
