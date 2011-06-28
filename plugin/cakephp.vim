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

function! s:open_controller(method, ...)
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            let controllers_root = fnamemodify(associations.controller,':h')
            let path = controllers_root . s:DS . s:match_controller(s:base_name(a:1)) . '.php'
            call s:open_window(path, a:method)
        elseif has_key(associations, 'controller')
            call s:open_window(associations.controller, a:method)
        else
            call s:error_message('Not enough information. Call from a view or model, or specify a controller.')
        endif
    endif
endfunction

function! s:open_model(method, ...)
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            let models_root = fnamemodify(associations.model,':h')
            let path = models_root . s:DS . s:base_name(a:1) . '.php'
            call s:open_window(path, a:method)
        elseif has_key(associations, 'model')
            call s:open_window(associations.model, a:method)
        else
            call s:error_message('Not enough information. Call from a view or controller, or specify a model.')
        endif
    endif
endfunction

function! s:open_view(method, ...)
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            if len(split(a:1,s:DS)) > 1
                let controller = split(a:1,s:DS)[0]
                let view = split(a:1,s:DS)[1]
                let path = associations.views . s:DS . s:match_view(s:base_name(controller)) . s:DS . view . '.ctp'
            elseif has_key(associations,'viewd')
                let path = associations.viewd . s:DS . a:1 . '.ctp'
                if a:1 == '$'
                    let path = associations.viewd
                endif
            else
                call s:error_message('Not enough information. Use "controller/view" syntax here.')
                return
            endif
            call s:open_window(path, a:method)
        elseif has_key(associations,'viewd')
            if len(split(associations.name,'_')) > 1
                let function_name = s:get_function_name()
                if function_name == 1
                    call s:open_window(associations.viewd, a:method)
                else
                    call s:open_window(associations.viewd . s:DS . function_name . '.ctp', a:method)
                endif
            else
                call s:open_window(associations.viewd, a:method)
            endif
        else
            call s:open_window(associations.views, a:method)
        endif
    endif
endfunction

function! s:open_file(name, extension, method, ...)
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            let path = associations[a:name] . s:DS . a:1 . '.' . a:extension
            call s:open_window(path, a:method)
        else
            call s:open_window(associations[a:name], a:method)
        endif
    endif
endfunction

function! s:open_window(path, method)
    exec a:method . ' ' . a:path
endfunction

function! s:associate()
    let path = expand('%:p')
    let name = remove(split(expand('%:r'),s:DS),-1) " Get filename from rel or abs path
    let ext = expand('%:e')
    let parent = expand('%:p:h:t')
    let parent_path = expand('%:p:h')
    let grandparent = expand('%:p:h:h:t')
    let grandparent_path = expand('%:p:h:h')
    let ggrandparent_path = expand('%:p:h:h:h')
    if parent == 'controllers'
        let base_name = s:base_name(name)
        let app_root = grandparent_path
    elseif parent == 'models'
        let base_name = s:base_name(name)
        let app_root = grandparent_path
    elseif grandparent == 'views'
        let base_name = s:base_name(parent)
        let app_root = ggrandparent_path
    elseif grandparent == 'webroot'
        let base_name = 0
        let app_root = ggrandparent_path
    else
        call s:error_message('Use within a CakePHP application.')
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
        let associations.controller = associations.controllers . s:DS . s:match_controller(base_name) . '.php'
        let associations.model      = associations.models . s:DS . base_name . '.php'
        let associations.viewd      = associations.views . s:DS . s:match_view(base_name)
    endif
    return associations
endfunction

function! s:base_name(name)
    let name = a:name
    if len(split(name,'_')) > 1 " Check if it is a controller
        return s:singularize(split(name,'_')[0])
    elseif s:is_plural(name)
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

function! s:is_singular(word)
    return s:singularize(s:pluralize(a:word)) == a:word
endfunction

function! s:is_plural(word)
    return s:pluralize(s:singularize(a:word)) == a:word
endfunction

function! s:match_controller(base_name)
    return s:pluralize(a:base_name) . '_controller'
endfunction

function! s:match_view(base_name)
    return s:pluralize(a:base_name)
endfunction

function! s:open_doc(...)
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
        call s:error_message('Not supported on your OS.')
    endif
endfunction

function! s:get_function_name()
    try
        let line_number = line('.')
        normal [[
        if split(getline('.'))[0] == 'function' && line('.') <= line_number
            return split(split(getline('.'))[1], '(')[0]
        else
            return 1
        endif
    catch
        return 1
    endtry
endfunction

function! s:arg_match(opts, A)
    if strlen(a:A) > 0
        return filter(a:opts, 'v:val[0:(strlen(a:A)-1)] == a:A') 
    else
        return a:opts
    endif
endfunction

function! s:glob_directory(direc, match)
    let associations = s:associate()
    if has_key(associations,a:direc)
        let files = split(glob(associations[a:direc] . '/*' . a:match),'\n')
        let files = map(files, 'remove(split(v:val, s:DS),-1)')
        let files = map(files, 'remove(split(v:val, a:match),0)')
        return files
    endif
    return []
endfunction
    
function! s:controller_comp(A,L,P)
    return s:arg_match(s:glob_directory('controllers', '_controller.php'), a:A)
endfunction

function! s:model_comp(A,L,P)
    return s:arg_match(s:glob_directory('models', '.php'), a:A)
endfunction

function! s:view_comp(A,L,P)
    let associations = s:associate()
    if (len(split(a:A,s:DS)) > 1 || a:A[strlen(a:A)-1] == s:DS) && has_key(associations, 'viewd')
        let dir = remove(split(a:A,s:DS),0)
        let viewd = associations.views . s:DS . dir
        let views = map(split(glob(viewd . '/*.ctp'),'\n'), 'dir . s:DS . remove(split(v:val, s:DS),-1)')
        let opts = map(views, 'remove(split(v:val,".ctp"),0)')
        if a:A[strlen(a:A)-1] == s:DS 
            return opts
        else
            return s:arg_match(opts,a:A)
        endif
    endif
    return s:arg_match(s:glob_directory('viewd', '.ctp'), a:A)
endfunction

function! s:css_comp(A,L,P)
    return s:arg_match(s:glob_directory('css', '.css'), a:A)
endfunction

function! s:js_comp(A,L,P)
    return s:arg_match(s:glob_directory('js', '.js'), a:A)
endfunction

function! s:log_comp(A,L,P)
    return s:arg_match(s:glob_directory('logs', '.log'), a:A)
endfunction

function! s:config_comp(A,L,P)
    return s:arg_match(s:glob_directory('config', '.php'), a:A)
endfunction

function! s:error_message(msg)
    echo '[cakephp.vim] ' . a:msg
endfunction

command! -n=? -complete=customlist,s:controller_comp Ccontroller call s:open_controller('e', <f-args>)
command! -n=? -complete=customlist,s:controller_comp CVcontroller call s:open_controller('vsp', <f-args>)
command! -n=? -complete=customlist,s:controller_comp CScontroller call s:open_controller('sp', <f-args>)
command! -n=? -complete=customlist,s:model_comp Cmodel call s:open_model('e', <f-args>)
command! -n=? -complete=customlist,s:model_comp CVmodel call s:open_model('vsp', <f-args>)
command! -n=? -complete=customlist,s:model_comp CSmodel call s:open_model('sp', <f-args>)
command! -n=? -complete=customlist,s:view_comp Cview call s:open_view('e', <f-args>)
command! -n=? -complete=customlist,s:view_comp CVview call s:open_view('vsp', <f-args>)
command! -n=? -complete=customlist,s:view_comp CSview call s:open_view('sp', <f-args>)
command! -n=? -complete=customlist,s:css_comp Ccss call s:open_file('css', 'css', 'e', <f-args>)
command! -n=? -complete=customlist,s:css_comp CVcss call s:open_file('css', 'css', 'vsp', <f-args>)
command! -n=? -complete=customlist,s:css_comp CScss call s:open_file('css', 'css', 'sp', <f-args>)
command! -n=? -complete=customlist,s:js_comp Cjs call s:open_file('css', 'js', 'e', <f-args>)
command! -n=? -complete=customlist,s:js_comp CVjs call s:open_file('js', 'js', 'vsp', <f-args>)
command! -n=? -complete=customlist,s:js_comp CSjs call s:open_file('js', 'js', 'sp', <f-args>)
command! -n=? -complete=customlist,s:log_comp Clog call s:open_file('logs', 'log', 'view', <f-args>)
command! -n=? -complete=customlist,s:config_comp Cconfig call s:open_file('config', 'php', 'e', <f-args>)
command! -n=0 Cassoc echo s:associate()
command! -n=? Cdoc call s:open_doc(<f-args>)
