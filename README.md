cakephp.vim
==================================================================================
A vim plugin for navigating and managing CakePHP applications. The goal is to 
mimic the functionality of rails.vim in the Cake environment. It's not quite there
yet, but I'm slowly adding things that (I think) make using Cake easier and faster.

Installation
----------------------------------------------------------------------------------

Using vim-pathogen and Git submodules:

    $ git submodule add git://github.com/ndreynolds/vim-cakephp.git bundle/cakephp

If you're not organizing your plugins with Pathogen and Git, clone the plugin 
and put it wherever you put the others. 

    $ git clone git://github.com/ndreynolds/vim-cakephp.git

That's it.

Getting Started (see [doc/cakephp.vim](https://github.com/ndreynolds/vim-cakephp/blob/master/doc/cakephp.txt) for full documentation)
----------------------------------------------------------------------------------

Start working on your Cake application as you normally would. No need to set any
variables, cakephp.vim will do all the work. 

### Just a few of the things you can do: ###

If you've got a controller, model, or any view open:
    
* `:Ccontroller` to open to the associated controller.

* `:Cmodel` to open to the associated model.

* `:Cview` to open the associated view directory in a file browser.

You can also run these with an argument:

* `:Ccontroller [name]` to open the specified controller.

* `:Cmodel [name]` to open the specified model.

* `:Cview [name]` to open the specified and associated view file.

(You don't need to use file extensions, or include '_controller', the plugin will
do all this for you. For example, both `:Ccontroller posts` and `:Ccontroller post`
will open the posts_controller.php file.)

Open a stylesheet:

* `:Ccss [name]` opens the given stylesheet.

Search the CakePHP API docs:

* `:Cdoc [query]` pulls up results in the default browser (if you're working locally).
* `:CLdoc [query]` pulls up results in Lynx (for working remotely).

Most commands have tab completion, so you'll only need a few keystrokes to jump 
to any given file. Commands that open files all have variants for vertical and 
horizontal split modes. There are a lot more commands so you owe it to yourself to
check out the docs if you use this plugin.

See [doc/cakephp.vim](https://github.com/ndreynolds/vim-cakephp/blob/master/doc/cakephp.txt) for the full documentation.

If you have vim configured to automatically load plugin help files, you can call 
this documentation with `:help cakephp` from within vim.
