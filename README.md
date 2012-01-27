cakephp.vim
================================================================================
A Vim plugin for navigating and managing CakePHP applications. The goal is to 
mimic the functionality of rails.vim in the Cake environment. It's not quite 
there yet, but I'm slowly adding things that (I think) make using Cake easier 
and faster.

*Note about CakePHP versions:*
CakePHP's naming conventions changed quite a bit from version 1.3 to 2.0. The 
`master` branch supports CakePHP 2.0+ but not 1.3. For 1.3 and below, you can 
checkout the tag `cake-1.3-compatible` which points to the last commit before 
the 2.0 shift. Simultaneous support for both CakePHP versions is on the todo 
list.

Installation
--------------------------------------------------------------------------------
With Pathogen, it's as easy as cloning the repository into your `bundle` 
directory.

    $ git submodule add git://github.com/ndreynolds/vim-cakephp.git bundle/cakephp

Getting Started (see [doc/cakephp.vim][1] for the full documentation)
--------------------------------------------------------------------------------
Start working on your Cake application as you normally would. No need to set any
variables, **cakephp.vim** will do all the work. 

### Just a few of the things you can do: ###

If you've got a controller, model, or any view open:
    
* `:Ccontroller` to open to the associated controller.

* `:Cmodel` to open to the associated model.

* `:Cview` to open the associated view directory in a file browser.

You can also run these with an argument:

* `:Ccontroller [name]` to open the specified controller.

* `:Cmodel [name]` to open the specified model.

* `:Cview [name]` to open the specified and associated view file.

Say you want to open the file in a tab, split window, vertically split window,
or even read it into the current buffer:

* Just use the syntax `:C[S,V,T,R][command]`
* For example, `:CRcontroller` will read in the associated controller. 
* `:CTmodel Post` will open the Post model in a new tab.

(You don't need to use file extensions, or include the controller suffix, the 
plugin will do all this for you. For example, both `:Ccontroller posts` and 
`:Ccontroller post` will open the PostsController.php file.)

Open a stylesheet:

* `:Ccss [name]` opens the given (CSS) stylesheet.
* `:Cless [name]` opens the given LESS stylesheet.
* `:Csass [name]` opens the given SASS stylesheet.

Search the CakePHP API docs:

* `:Cdoc [query]` pulls up results in the default browser (if you're working 
  locally).
* `:Cldoc [query]` pulls up results in Lynx (for when your working over SSH).

But that's not all, you also get commands to open Elements, Emails, Tasks, 
Commands, Helpers, Components, Pages, Scaffolds, Tests, and more (for the low, 
low price of $19.99)...

Most commands have tab completion, so you'll only need a few keystrokes to jump 
to any given file. Commands that open files all have variants for vertical and 
horizontal split modes. There are a lot more commands so you owe it to yourself 
to check out the docs if you use this plugin.

See [doc/cakephp.vim][1] for the full documentation.

If you have Vim configured to automatically load plugin help files, you can call
the documentation with `:help cakephp` from within Vim.

And of course, if you'd like to help, or want a feature I didn't think of, 
submit a pull request.

[1]: https://github.com/ndreynolds/vim-cakephp/blob/master/doc/cakephp.txt
