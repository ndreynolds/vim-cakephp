" cakephp.vim
" A vim plugin for navigating and managing CakePHP projects
" Version: 1.3
" Author: Nick Reynolds
" Repository: http://github.com/ndreynolds/vim-cakephp
" License: Public Domain


" Script setup ------------------------------------------------------------- {{{

if exists("g:loaded_cakephp") || &cp
    finish
endif
let g:loaded_cakephp = "1.3"

let s:cpo_save = &cpo
set cpo&vim

let s:statusline_modified = 0

" }}}


" Startup functions -------------------------------------------------------- {{{

" Detect the operating system.
function! s:detect_os()
    " This tells us which directory separator to use, as well as which OS-specific
    " tools might be available.
    let s:DS = "/"
    if has("unix") && system("uname") =~ "Darwin"
        let s:OS = "mac"
    elseif has("unix")
        let s:OS = "unix"
    elseif has("win32")
        let s:OS = "windows"
        let s:DS = '\'
    else
        let s:OS = "unknown"
    endif
endfunction

" Load the autoload functions.
function! s:autoload()
    " Currently this isn't called by anything.
    if !exists("g:autoloaded_cakephp")
        runtime! autoload/cakephp.vim
    endif
endfunction

" Detect a CakePHP application by running the associations builder.
function! s:detect()
    call s:detect_os()
    let check = s:force_associate(1)
    if !empty(check)
        if s:cake_check(check)
            call s:startup()
        endif
    endif
endfunction

" Delegate startup tasks. Called upon successful detect()
function s:startup()
    call s:set_commands()
    call s:set_statusline()
endfunction

" Put [CakePHP] into the statusline.
function! s:set_statusline()
    " Save the original so we can put it back.
    let s:statusline_original = &statusline
    " TODO - magically inject it into a customized statusline like 
    " vim-rails does.
    set statusline=%f\ %y\ [CakePHP]\ %r%=\ %-20.(%l,%c-%v\ %)%P
    let s:statusline_modified = 1
endfunction

" Reset the statusline.
function! s:reset_statusline()
    if s:statusline_modified
        let s:statusline_modified = 0
    endif
endfunction

" After running associate, verify that we're not in some sort of Rails or Zend 
" app. We check for a few required (and reasonably unique) files.
function! s:cake_check(check)
    return filereadable(a:check.config . s:DS . 'bootstrap.php') && 
         \ filereadable(a:check.config . s:DS . 'core.php') && 
         \ filereadable(a:check.config . s:DS . 'routes.php')
endfunction

" }}}


" Associate callers -------------------------------------------------------- {{{

" Get associations lazily
function! s:associate(...)
    if !exists('s:associations') 
        if a:0 > 0
            let s:associations = s:build_associations(a:1)
        else
            let s:associations = s:build_associations()
        endif
    endif
    return s:associations
endfunction

" Force the associations.
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

" Examines the buffer file path to see if it *might* be part of a Cake app.
" We do a more concrete check afterwards in cake_check()
function! s:build_associations(...)

    " *Try* to get the filename. 
    " If there's no buffer, this will fail. So we need a catch in place.
    try
        let name = s:tail(expand('%:r'))
    catch
        return {}
    endtry

    " Set some paths
    let parent   = expand('%:p:h')
    let gparent  = expand('%:p:h:h')
    let g2parent = expand('%:p:h:h:h')
    let g3parent = expand('%:p:h:h:h:h') 

    " Default base name evaluates to false
    let base_name = 0

    " Are we within Controller/ ?
    if s:tail(parent) == 'Controller'
        let base_name = s:base_name(name)
        let app_root = gparent

    " ...within Model/ ?
    elseif s:tail(parent) == 'Model'
        let base_name = s:base_name(name)
        let app_root = gparent

    " ...within View default sub-dir?
    elseif s:tail(gparent) == 'View' && 
        \ s:in_list(['Layouts', 'Elements', 'Emails', 'Errors', 'Helper', 
        \            'Pages', 'Scaffolds'], s:tail(parent))
        let app_root = g2parent

    " ...within View controller sub-dir?
    elseif s:tail(gparent) == 'View'
        let base_name = s:base_name(s:tail(parent))
        let app_root = g2parent

    " ...within webroot/ or Config/ or Plugin/ ?
    elseif s:in_list(['webroot', 'Config', 'Plugin'], s:tail(parent))
        let app_root = gparent

    " ...within webroot/*/ or Controller/*/ or tmp/*/ ?
    elseif s:in_list(['webroot', 'Controller', 'Model', 'tmp'], s:tail(gparent))
        let app_root = g2parent

    " ...within webroot/*/*/ ?
    elseif s:tail(g2parent) == 'webroot'
        let app_root = g3parent

    " ...guess not. Return empty dict. Error if called with arg.
    else
        if !(a:0 > 0 && a:1 == 1)
            call s:error('Use within a CakePHP application.')
        endif
        return {} 
    endif

    " Define some associations if we've made it this far.
    let associations = {
        \ 'name'        : name,
        \ 'app'         : app_root,
        \ 'webroot'     : s:pjoin(app_root, 'webroot'),
        \ 'controllers' : s:pjoin(app_root, 'Controller'),
        \ 'models'      : s:pjoin(app_root, 'Model'),
        \ 'views'       : s:pjoin(app_root, 'View'),
        \ 'tmp'         : s:pjoin(app_root, 'tmp'),
        \ 'config'      : s:pjoin(app_root, 'Config'),
        \ 'css'         : s:pjoin(app_root, 'webroot', 'css'),
        \ 'js'          : s:pjoin(app_root, 'webroot', 'js'),
        \ 'logs'        : s:pjoin(app_root, 'tmp', 'logs'),
        \ 'layouts'     : s:pjoin(app_root, 'View', 'Layouts'),
        \ 'behaviors'   : s:pjoin(app_root, 'Model', 'Behavior'),
        \ 'components'  : s:pjoin(app_root, 'Controller', 'Component') }

    " Define specific MVC associations, if possible.
    if !empty(base_name)
        let associations.controller = s:pjoin(associations.controllers, s:controllerize(base_name) . '.php')
        let associations.model      = s:pjoin(associations.models, base_name . '.php')
        let associations.viewd      = s:pjoin(associations.views, s:viewify(base_name))
    endif

    " Return our associations.
    return associations

endfunction

" }}}


" Helper functions --------------------------------------------------------- {{{

" Return true if el is a member of list.
function! s:in_list(list, el)
    let list = filter(a:list, 'v:val == a:el')
    return len(list) > 0 ? 1 : 0
endfunction

" Substitute a string using a pattern.
function! s:sub(str,pat,rep)
    return substitute(a:str, '\v\C'.a:pat, a:rep, '')
endfunction

" Return the result of matchstr()
function! s:mats(str, pat)
    return matchstr(a:str, a:pat)
endfunction

" Return the tail of a path, using the DS constant.
function! s:tail(path)
    return split(a:path, s:DS)[-1]
endfunction

" Join string arguments, using the DS constant.
function! s:pjoin(...)
    return join(a:000, s:DS)
endfunction

" Echo an error message, with prefix.
function! s:error(msg)
    echoerr '[cakephp.vim] ' . a:msg
endfunction

" (Try to) get the name of the function the cursor is within.
function! s:get_function_name()
    try
        let line_number = line('.')
        normal! [[
        if split(getline('.'))[0] == 'function' && line('.') <= line_number
            return split(split(getline('.'))[1], '(')[0]
        else
            return 1
        endif
    catch
        return 1
    endtry
endfunction

" Recursively grep the application's root.
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
        s:error("Error: grep isn't executable.")
    else
        s:error("CakePHP app not found")
    endif
endfunction

" Filter options to return the subset that starts with the given A value.
function! s:arg_match(opts, A)
    if strlen(a:A) > 0
        return filter(a:opts, 'v:val[0:(strlen(a:A)-1)] == a:A') 
    else
        return a:opts
    endif
endfunction

" Glob a directory, given an associations dictionary key, given a unix filenamei
" pattern.
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

" }}}


" MVC helper functions ----------------------------------------------------- {{{

" Return the base name (same as Model name) of a MVC entity.
" Ex. PostsController => Post, Users => User
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

" Return the controller name, given the base name.
function! s:controllerize(base_name)
    return s:pluralize(a:base_name) . 'Controller'
endfunction

" Return the view sub-directory name, given the base name.
function! s:viewify(base_name)
    return s:pluralize(a:base_name)
endfunction

" }}}


" Inflection --------------------------------------------------------------- {{{

" Singularize an (english) word. Borrowed from github.com/tpope/vim-rails
" Ex. boxes => box
function! s:singularize(word)
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

" Pluralize an (english) word. Borrowed from github.com/tpope/vim-rails
" Ex. box => boxes
function! s:pluralize(word)
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

" Test singularity using double negation.
function! s:is_singular(word)
    " it's not perfect, but does work most of the time.
    return s:singularize(s:pluralize(a:word)) == a:word
endfunction

" Test plurality using double negation.
function! s:is_plural(word)
    return s:pluralize(s:singularize(a:word)) == a:word
endfunction

" }}}


" Openers ------------------------------------------------------------------ {{{

" Open a controller, delegates to open_buffer()
function! s:open_controller(method, ...)
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            if a:1 == 'App'
                let path = associations.controllers . s:DS . 'AppController.php'
            else
                let path = associations.controllers . s:DS . s:controllerize(s:base_name(a:1)) . '.php'
            endif
            call s:open_buffer(path, a:method)
        elseif has_key(associations, 'controller')
            call s:open_buffer(associations.controller, a:method)
        else
            call s:error("You'll need to specify a controller from here.")
        endif
    endif
endfunction

" Open a model, delegates to open_buffer()
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
            call s:open_buffer(path, a:method)
        elseif has_key(associations, 'model')
            call s:open_buffer(associations.model, a:method)
        else
            call s:error("You'll need to specify a model from here.")
        endif
    endif
endfunction

" Open a view, delegates to open_buffer()
function! s:open_view(method, ...)
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            if len(split(a:1,s:DS)) > 1
                let controller = split(a:1,s:DS)[0]
                let view = split(a:1,s:DS)[1]
                let path = associations.views . s:DS . s:viewify(s:base_name(controller)) . s:DS . view . '.ctp'
            elseif has_key(associations,'viewd')
                let path = associations.viewd . s:DS . a:1 . '.ctp'
                if a:1 == '$'
                    let path = associations.viewd
                endif
            else
                call s:error("You'll need to use 'controller/view' syntax here.")
                return
            endif
            call s:open_buffer(path, a:method)
        elseif has_key(associations,'viewd')
            if len(split(associations.name,'_')) > 1
                let function_name = s:get_function_name()
                if function_name == 1
                    call s:open_buffer(associations.viewd, a:method)
                else
                    call s:open_buffer(associations.viewd . s:DS . function_name . '.ctp', a:method)
                endif
            else
                call s:open_buffer(associations.viewd, a:method)
            endif
        else
            call s:open_buffer(associations.views, a:method)
        endif
    endif
endfunction

" Open a file, delegates to open_buffer()
function! s:open_file(name, extension, method, ...)
    let associations = s:associate()
    if !empty(associations)
        if a:0 > 0
            let path = associations[a:name] . s:DS . a:1 . a:extension
            call s:open_buffer(path, a:method)
        else
            call s:open_buffer(associations[a:name], a:method)
        endif
    endif
endfunction

" Open the CakePHP API docs, optionally given a search term.
function! s:open_doc(type, ...)
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
            call s:error('Not supported on your OS.')
        endif
    endif
endfunction

" Open a buffer with exec and the given method and path.
function! s:open_buffer(path, method)
    exec a:method . ' ' . a:path
endfunction

" }}}


" MVC completion functions ------------------------------------------------- {{{

" Complete 
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

" }}}


" File completion functions ------------------------------------------------ {{{

" Dictionary of file commands and (directory, pattern) pairs
let s:CakeFileCommands = {
    \ 'Ccss'      : ['css', '.css'], 
    \ 'Cstyle'    : ['css', '.css'],
    \ 'Cjs'       : ['js', '.js'], 
    \ 'Ccoffee'   : ['js', '.coffee'], 
    \ 'Cless'     : ['css', '.less'], 
    \ 'Csass'     : ['css', '.sass'], 
    \ 'Clayout'   : ['layouts', '.ctp'],
    \ 'Cbehavior' : ['behaviors', '.php'], 
    \ 'Celement'  : ['elements', '.ctp'], 
    \ 'Ctest'     : ['tests', '.php'], 
    \ 'Cscaffold' : ['scaffolds', '.ctp'], 
    \ 'Cpage'     : ['pages', '.ctp'], 
    \ 'Chelper'   : ['helpers', '.php'], 
    \ 'Cconfig'   : ['config', '.php'], 
    \ 'Cemail'    : ['emails', '.ctp'], 
    \ 'Ccomponent': ['components', '.php'], 
    \ 'Clog'      : ['logs', '.log'] }

" Command modifiers (i.e. :CSstyle to open in split window)
let s:CakeCmdModifiers = {
    \ 'S': 'sp',
    \ 'V': 'vsp',
    \ 'T': 'tab',
    \ 'R': 'r', 
    \ ' ': 'e' }

" Returns 'customlist' completion for a file command.
function! s:file_comp(A,L,P)
    " Must retrieve command to figure out how it should be completed:
    let cmd = matchstr(a:L,'\u\w\+')
    " Strip command modifiers
    let base_cmd = s:sub(cmd, '[SVTR]', '')
    let dir = s:CakeFileCommands[base_cmd][0]
    let ext = s:CakeFileCommands[base_cmd][1]
    return s:arg_match(s:glob_directory(dir, ext), a:A)
endfunction

" Declare a file command, given a CakeFileCommands key.
function! s:add_file_cmd(cmd)
    " Drop the leading C for later
    let trailing_cmd = s:sub(a:cmd, 'C', '')
    " Get the directory key and the file extension
    let dir = s:CakeFileCommands[a:cmd][0]
    let ext = s:CakeFileCommands[a:cmd][1]
    " Make commands for each command modifier
    for [k, v] in items(s:CakeCmdModifiers)
        let fullcmd = "C" . (k == ' ' ? '' : k) . trailing_cmd
        exe "command! -n=? -complete=customlist,s:file_comp " . fullcmd . 
           \" call s:open_file('" . dir . "', '" . ext . "', '" . v . "', <f-args>)"
    endfor
endfunction

" Declare all file commands.
function! s:add_file_cmds()
    for k in keys(s:CakeFileCommands)
        call s:add_file_cmd(k)
    endfor
endfunction

" }}}


" Command declarations ---------------------------------------------------- {{{ 

function! s:set_commands()
    command! -n=? -complete=customlist,s:controller_comp Ccontroller call s:open_controller('e', <f-args>)
    command! -n=? -complete=customlist,s:controller_comp CVcontroller call s:open_controller('vsp', <f-args>)
    command! -n=? -complete=customlist,s:controller_comp CScontroller call s:open_controller('sp', <f-args>)
    command! -n=? -complete=customlist,s:controller_comp CTcontroller call s:open_controller('tab', <f-args>)
    command! -n=? -complete=customlist,s:controller_comp CRcontroller call s:open_controller('r', <f-args>)
    command! -n=? -complete=customlist,s:model_comp Cmodel call s:open_model('e', <f-args>)
    command! -n=? -complete=customlist,s:model_comp CVmodel call s:open_model('vsp', <f-args>)
    command! -n=? -complete=customlist,s:model_comp CSmodel call s:open_model('sp', <f-args>)
    command! -n=? -complete=customlist,s:model_comp CTmodel call s:open_model('tab', <f-args>)
    command! -n=? -complete=customlist,s:model_comp CRmodel call s:open_model('r', <f-args>)
    command! -n=? -complete=customlist,s:view_comp Cview call s:open_view('e', <f-args>)
    command! -n=? -complete=customlist,s:view_comp CVview call s:open_view('vsp', <f-args>)
    command! -n=? -complete=customlist,s:view_comp CSview call s:open_view('sp', <f-args>)
    command! -n=? -complete=customlist,s:view_comp CTview call s:open_view('tab', <f-args>)
    command! -n=? -complete=customlist,s:view_comp CRview call s:open_view('r', <f-args>)
    command! -n=? Cdoc call s:open_doc('', <f-args>)
    command! -n=? CLdoc call s:open_doc('lynx', <f-args>)
    command! -n=1 -bang Cgrep call s:grep_app_root(<bang>0, <f-args>)
    call s:add_file_cmds()
endfunction

command! -n=0 Cassoc echo s:force_associate(1)

" }}}


" Autocommand group -------------------------------------------------------- {{{

augroup CakeDetect
    autocmd BufEnter *.ctp,*.php,*.js,*.coffee,*.css,*.log :call s:detect()
    autocmd BufEnter * :call s:reset_statusline()
augroup END

" }}}
