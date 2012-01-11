" cakephp.vim
" A vim plugin for navigating and managing CakePHP projects
" Version: 1.2
" Author: Nick Reynolds
" Repository: http://github.com/ndreynolds/vim-cakephp
" License: Public Domain

" Script setup ------------------------------------------------------------- {{{
if exists("g:loaded_cakephp") || &cp
    finish
endif

let g:loaded_cakephp = '1.2'
let s:cpo_save = &cpo
set cpo&vim

let s:statusline_modified = 0
" }}}

" Detect OS ---------------------------------------------------------------- {{{
let s:DS = '/'
if has('unix') && system('uname') =~ 'Darwin'
    let s:OS = 'mac'
elseif has('unix')
    let s:OS = 'unix'
elseif has('win32')
    let s:OS = 'windows'
    let s:DS = '\'
else
    let s:OS = 'unknown'
endif
" }}}

" Openers ------------------------------------------------------------------ {{{
function! s:open_controller(method, ...)
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            if a:1 == 'App'
                let path = associations.controllers . s:DS . 'AppController.php'
            else
                let path = associations.controllers . s:DS . s:match_controller(s:base_name(a:1)) . '.php'
            endif
            call s:open_window(path, a:method)
        elseif has_key(associations, 'controller')
            call s:open_window(associations.controller, a:method)
        else
            call s:error_message("You'll need to specify a controller from here.")
        endif
    endif
endfunction

function! s:open_model(method, ...)
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            if a:1 == 'App'
                let path = associations.models . s:DS . 'AppModel.php'
            else
                let path = associations.models . s:DS . s:base_name(a:1) . '.php'
            endif
            let path = associations.models . s:DS . s:base_name(a:1) . '.php'
            call s:open_window(path, a:method)
        elseif has_key(associations, 'model')
            call s:open_window(associations.model, a:method)
        else
            call s:error_message("You'll need to specify a model from here.")
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
                call s:error_message("You'll need to use 'controller/view' syntax here.")
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
" }}}

function! s:reset_statusline()
    if s:statusline_modified
        set statusline=
        let s:statusline_modified = 0
    endif
endfunction

function! s:startup()
    let check = s:force_associate(1)
    if !empty(check)
        if filereadable(check.config . s:DS . 'bootstrap.php') && filereadable(check.config . s:DS . 'core.php') && filereadable(check.config . s:DS . 'routes.php')
            set statusline=%f\ %y\ [CakePHP]\ %r%=\ %-20.(%l,%c-%v\ %)%P
            let s:statusline_modified = 1
            call s:set_commands()
        endif
    endif
endfunction

" Associate callers -------------------------------------------------------- {{{
function! s:associate(...)
    " Get associations lazily
    if !exists('s:associations') 
        if a:0 > 0
            let s:associations = s:build_associations(a:1)
        else
            let s:associations = s:build_associations()
        endif
    endif
    return s:associations
endfunction

function! s:force_associate(...)
    if a:0 > 0
        let s:associations = s:build_associations(a:1)
    else
        let s:associations = s:build_associations()
    endif
    return s:associations
endfunction
" }}}

" Association builder ------------------------------------------------------ {{{
function! s:build_associations(...)
    let path = expand('%:p')
    try
        let name = split(expand('%:r'), s:DS)[-1] " Get filename from rel or abs path
    catch
        return {}
    endtry
    let ext = expand('%:e')
    let parent = expand('%:p:h:t')
    let parent_path = expand('%:p:h')
    let grandparent = expand('%:p:h:h:t')
    let grandparent_path = expand('%:p:h:h')
    let ggrandparent_path = expand('%:p:h:h:h')
    let base_name = 0
    if parent == 'Controller'
        let base_name = s:base_name(name)
        let app_root = grandparent_path
    elseif parent == 'Model'
        let base_name = s:base_name(name)
        let app_root = grandparent_path
    elseif grandparent == 'View' && parent == 'Layouts' 
        let app_root = ggrandparent_path
    elseif grandparent == 'View'
        let base_name = s:base_name(parent)
        let app_root = ggrandparent_path
    elseif s:in_list(['webroot', 'Config', 'Plugin'], parent)
        let app_root = grandparent_path
    elseif s:in_list(['webroot', 'Controller', 'Model', 'tmp'], grandparent) 
        let app_root = ggrandparent_path
    else
        if !(a:0 > 0 && a:1 == 1)
            call s:error_message('Use within a CakePHP application.')
        endif
        return {} 
    endif
    let associations = {}
    " Basic associations that don't require being called from an MVC element
    let associations.name        = name
    let associations.app         = app_root
    let associations.webroot     = app_root . s:DS . 'webroot' 
    let associations.controllers = app_root . s:DS . 'Controller'
    let associations.models      = app_root . s:DS . 'Model'
    let associations.views       = app_root . s:DS . 'View'
    let associations.tmp         = app_root . s:DS . 'tmp'
    let associations.config      = app_root . s:DS . 'Config'
    let associations.css         = associations.webroot . s:DS . 'css'
    let associations.js          = associations.webroot . s:DS . 'js'
    let associations.logs        = associations.tmp . s:DS . 'logs'
    let associations.layouts     = associations.views . s:DS . 'Layouts'
    let associations.behaviors   = associations.models . s:DS . 'Behavior'
    let associations.components  = associations.controllers . s:DS . 'Component'
    " Specific associations that require being called from an MVC element.
    if !empty(base_name)
        let associations.controller = associations.controllers . s:DS . s:match_controller(base_name) . '.php'
        let associations.model      = associations.models . s:DS . base_name . '.php'
        let associations.viewd      = associations.views . s:DS . s:match_view(base_name)
    endif
    return associations
endfunction
" }}}

function! s:base_name(name)
    let name = a:name
    if name =~ 'Controller' 
        let splits = split(name, 'C')
        return s:singularize(splits[0])
    elseif s:is_plural(name)
        return s:singularize(name)
    else
        return name
    endif
endfunction

" Helper functions --------------------------------------------------------- {{{
function! s:in_list(list, el)
    " Checks if the given element is a member of the given list
    let list = filter(a:list, 'v:val == a:el')
    return len(list) > 0 ? 1 : 0
endfunction

function! s:sub(str,pat,rep)
    return substitute(a:str, '\v\C'.a:pat, a:rep, '')
endfunction
" }}}

" Inflection --------------------------------------------------------------- {{{
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
" }}}

function! s:match_controller(base_name)
    return s:pluralize(a:base_name) . 'Controller'
endfunction

function! s:match_view(base_name)
    return s:pluralize(a:base_name)
endfunction

" Doc opener --------------------------------------------------------------- {{{
function! s:open_doc(type,...)
    let url = 'http://api.cakephp.org/'
    if a:0 > 0
        let url .= 'search/' . join(split(a:1),'\%20')
    endif
    if a:type == 'lynx'
        exec '! lynx '. url
    else
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
    endif
endfunction
" }}}

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

function! s:grep_app_root(bang, pattern)
    let associations = s:associate()
    if !empty(associations) && executable('grep')
        if a:bang
            exec '! grep -r --color ' . a:pattern . ' ' . associations.app
        else
            let exclusions = '--exclude-dir="' . associations.tmp . '" '
            let exclusions .= '--exclude-dir="' . associations.config . '" '
            let exclusions .= '--exclude="' . associations.webroot . s:DS . 'test.php" '
            exec '! grep -r  --color ' . exclusions . a:pattern . ' ' . associations.app
        endif
    elseif !executable('grep') 
        s:error_message("Error: grep isn't executable.")
    else
        s:error_message("CakePHP app not found")
    endif
endfunction

function! s:arg_match(opts, A)
    if strlen(a:A) > 0
        return filter(a:opts, 'v:val[0:(strlen(a:A)-1)] == a:A') 
    else
        return a:opts
    endif
endfunction

function! s:glob_directory(direc, pattern)
    let associations = s:associate()
    if has_key(associations, a:direc)
        let files = split(glob(associations[a:direc] . s:DS . '*' . a:pattern),'\n')
        let files = map(files, 'remove(split(v:val, s:DS),-1)')
        let files = map(files, 'remove(split(v:val, a:pattern),0)')
        return files
    endif
    return []
endfunction

" Custom completion functions ---------------------------------------------- {{{
function! s:controller_comp(A,L,P)
    return s:arg_match(s:glob_directory('controllers', 'Controller.php'), a:A)
endfunction

function! s:model_comp(A,L,P)
    return s:arg_match(s:glob_directory('models', '.php'), a:A)
endfunction

function! s:view_comp(A,L,P)
    let associations = s:associate()
    if (len(split(a:A,s:DS)) > 1 || a:A[strlen(a:A)-1] == s:DS)
        let dir = remove(split(a:A,s:DS),0)
        let viewd = associations.views . s:DS . dir
        let views = map(split(glob(viewd . s:DS . '*.ctp'),'\n'), 'dir . s:DS . remove(split(v:val, s:DS),-1)')
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

function! s:coffee_comp(A,L,P)
    return s:arg_match(s:glob_directory('js', '.coffee'), a:A)
endfunction

function! s:log_comp(A,L,P)
    return s:arg_match(s:glob_directory('logs', '.log'), a:A)
endfunction

function! s:config_comp(A,L,P)
    return s:arg_match(s:glob_directory('config', '.php'), a:A)
endfunction

function! s:layout_comp(A,L,P)
    return s:arg_match(s:glob_directory('layouts', '.ctp'), a:A)
endfunction

function! s:behavior_comp(A,L,P)
    return s:arg_match(s:glob_directory('behaviors', '.php'), a:A)
endfunction

function! s:helper_comp(A,L,P)
    return s:arg_match(s:glob_directory('helpers', '.php'), a:A)
endfunction

function! s:component_comp(A,L,P)
    return s:arg_match(s:glob_directory('components', '.php'), a:A)
endfunction
" }}}

function! s:error_message(msg)
    echo '[cakephp.vim] ' . a:msg
endfunction

" Command declarations ---------------------------------------------------- {{{ 
function! s:set_commands()
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
    command! -n=? -complete=customlist,s:css_comp Cstyle call s:open_file('css', 'css', 'e', <f-args>)
    command! -n=? -complete=customlist,s:css_comp CVstyle call s:open_file('css', 'css', 'vsp', <f-args>)
    command! -n=? -complete=customlist,s:css_comp CSstyle call s:open_file('css', 'css', 'sp', <f-args>)
    command! -n=? -complete=customlist,s:js_comp Cjs call s:open_file('js', 'js', 'e', <f-args>)
    command! -n=? -complete=customlist,s:js_comp CVjs call s:open_file('js', 'js', 'vsp', <f-args>)
    command! -n=? -complete=customlist,s:js_comp CSjs call s:open_file('js', 'js', 'sp', <f-args>)
    command! -n=? -complete=customlist,s:coffee_comp Ccoffee call s:open_file('js', 'coffee', 'e', <f-args>)
    command! -n=? -complete=customlist,s:coffee_comp CVcoffee call s:open_file('js', 'coffee', 'vsp', <f-args>)
    command! -n=? -complete=customlist,s:coffee_comp CScoffee call s:open_file('js', 'coffee', 'sp', <f-args>)
    command! -n=? -complete=customlist,s:layout_comp Clayout call s:open_file('layouts', 'ctp', 'e', <f-args>)
    command! -n=? -complete=customlist,s:layout_comp CVlayout call s:open_file('layouts', 'ctp', 'vsp', <f-args>)
    command! -n=? -complete=customlist,s:layout_comp CSlayout call s:open_file('layouts', 'ctp', 'sp', <f-args>)
    command! -n=? -complete=customlist,s:behavior_comp Cbehavior call s:open_file('behaviors', 'php', 'e', <f-args>)
    command! -n=? -complete=customlist,s:behavior_comp CVbehavior call s:open_file('behaviors', 'php', 'vsp', <f-args>)
    command! -n=? -complete=customlist,s:behavior_comp CSbehavior call s:open_file('behaviors', 'php', 'sp', <f-args>)
    command! -n=? -complete=customlist,s:component_comp Ccomponent call s:open_file('components', 'php', 'e', <f-args>)
    command! -n=? -complete=customlist,s:component_comp CVcomponent call s:open_file('components', 'php', 'vsp', <f-args>)
    command! -n=? -complete=customlist,s:component_comp CScomponent call s:open_file('components', 'php', 'sp', <f-args>)
    command! -n=? -complete=customlist,s:log_comp Clog call s:open_file('logs', 'log', 'view', <f-args>)
    command! -n=? -complete=customlist,s:config_comp Cconfig call s:open_file('config', 'php', 'e', <f-args>)
    command! -n=0 Cassoc echo s:associate()
    command! -n=? Cdoc call s:open_doc('', <f-args>)
    command! -n=? CLdoc call s:open_doc('lynx', <f-args>)
    command! -n=1 -bang Cgrep call s:grep_app_root(<bang>0, <f-args>)
endfunction
" }}}

autocmd BufEnter * :call s:reset_statusline()
autocmd BufEnter *.ctp,*.php,*.js,*.coffee,*.css,*.log :call s:startup()
