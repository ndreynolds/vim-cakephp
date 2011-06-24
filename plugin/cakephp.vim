" cakephp.vim
" A vim plugin for navigating and managing CakePHP projects
" Version: 1.0
" Author: Nick Reynolds
" Repository: http://github.com/ndreynolds/vim-cakephp
" License: Public Domain

if exists("g:loaded_cakephp") || &cp
    finish
endif

let g:loaded_cakephp = '1.0'
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
        elseif has_key(associations, 'controller')
            call s:openWindow(associations.controller, a:method)
        else
            echo 'Not enough information. Call from a view or model, or specify a controller.'
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
        elseif has_key(associations, 'model')
            call s:openWindow(associations.model, a:method)
        else
            echo 'Not enough information. Call from a view or controller, or specify a model.'
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
                let path = associations.views . s:DS . s:matchView(s:baseName(controller)) . s:DS . view . '.ctp'
            elseif has_key(associations,'viewd')
                let path = associations.viewd . s:DS . a:1 . '.ctp'
                if a:1 == '$'
                    let path = associations.viewd
                endif
            else
                echo 'Not enough information. Use "controller/view" syntax here.'
                return
            endif
            call s:openWindow(path, a:method)
        elseif has_key(associations,'viewd')
            if len(split(associations.name,'_')) > 1
                " Try to open the current function's view by default within controllers.
                call s:openWindow(associations.viewd . s:DS . s:getFunctionName() . '.ctp', a:method)
            else
                call s:openWindow(associations.viewd, a:method)
            endif
        else
            call s:openWindow(associations.views, a:method)
        endif
    endif
endfunction

function! s:openFile(name, extension, method, ...)
    " Open static files like js or css, provided their path is in
    " associations.
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            let path = associations[a:name] . s:DS . a:1 . '.' . a:extension
            call s:openWindow(path, a:method)
        else
            call s:openWindow(associations[a:name], a:method)
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
    elseif grandparent == 'webroot'
        let base_name = 0
        let app_root = ggrandparent_path
    else
        echo 'Could not find a CakePHP app. Call from inside a model, controller, view, or the webroot.' 
        return {}
    endif
    let associations = {}
    " Basic associations that don't require being called from an MVC element
    let associations.name        = name
    let associations.app         = app_root
    let associations.css         = app_root . s:DS . 'webroot' . s:DS . 'css'
    let associations.js          = app_root . s:DS . 'webroot' . s:DS . 'js'
    let associations.controllers = app_root . s:DS . 'controllers'
    let associations.models      = app_root . s:DS . 'models'
    let associations.views       = app_root . s:DS . 'views'
    let associations.logs        = app_root . s:DS . 'tmp' . s:DS . 'logs'
    let associations.config      = app_root . s:DS . 'config'
    " Specific associations that require being called from an MVC element.
    if !empty(base_name)
        let associations.controller = associations.controllers . s:DS . s:matchController(base_name) . '.php'
        let associations.model      = associations.models . s:DS . base_name . '.php'
        let associations.viewd      = associations.views . s:DS . s:matchView(base_name)
    endif
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

function! s:matchView(base_name)
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
    if s:OS == 'mac'
        exec 'silent ! open ' . url . ' &'
        exec 'redraw!' 
    elseif s:OS == 'windows'
        exec 'silent ! start ' . url 
        exec 'redraw!' 
    elseif s:OS == 'unix' 
        exec 'silent ! gnome-open ' . url . ' &'
        exec 'redraw!'
    else
        echo "Couldn't recognize your Operating System."
    endif
endfunction

function! s:getFunctionName()
    normal [[
    return split(split(getline('.'))[1], '(')[0]
endfunction

command! -n=? Ccontroller call s:openController('e', <f-args>)
command! -n=? CVcontroller call s:openController('vsp', <f-args>)
command! -n=? CScontroller call s:openController('sp', <f-args>)
command! -n=? Cmodel call s:openModel('e', <f-args>)
command! -n=? CVmodel call s:openModel('vsp', <f-args>)
command! -n=? CSmodel call s:openModel('sp', <f-args>)
command! -n=? Cview call s:openView('e', <f-args>)
command! -n=? CVview call s:openView('vsp', <f-args>)
command! -n=? CSview call s:openView('sp', <f-args>)
command! -n=? Ccss call s:openFile('css', 'css', 'e', <f-args>)
command! -n=? CVcss call s:openFile('css', 'css', 'vsp', <f-args>)
command! -n=? CScss call s:openFile('css', 'css', 'sp', <f-args>)
command! -n=? Cjs call s:openFile('css', 'js', 'e', <f-args>)
command! -n=? CVjs call s:openFile('js', 'js', 'vsp', <f-args>)
command! -n=? CSjs call s:openFile('js', 'js', 'sp', <f-args>)
command! -n=? Clog call s:openFile('logs', 'log', 'sp', <f-args>)
command! -n=? Cconfig call s:openFile('config', 'php', 'sp', <f-args>)
command! -n=0 Cassoc echo s:associate()
command! -n=? Cdoc call s:openDoc(<f-args>)
command! -n=? Cfunc echo s:getFunctionName()
