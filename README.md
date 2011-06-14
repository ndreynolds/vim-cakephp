cakephp.vim
==================================================================================
A toolset for navigating and managing CakePHP applications. The goal is to mimic
the functionality of vim-rails in the Cake environment. A similar plugin, cake.vim,
already exists. While it's great, I wanted to make the commands more intuitive and 
offer a bit more functionality. I started from scratch, basing some of it off
vim-rails. It's currently a work in progress.

Installation
----------------------------------------------------------------------------------

Using vim-pathogen and Git submodules:

    $ git submodule add git://github.com/ndreynolds/vim-cakephp.git bundle/cakephp

If you're not organizing your plugins with Pathogen and Git, clone/dl the plugin 
and put it wherever you put the others.

    $ git clone git://github.com/ndreynolds/vim-cakephp.git

That's it.

Getting Started (see [doc/cakephp.vim](https://github.com/ndreynolds/vim-cakephp/blob/master/doc/cakephp.txt) for full documentation)
----------------------------------------------------------------------------------

Start working on your Cake application as you normally would. No need to set any
variables, cakephp.vim will do all the work.

If you've got a controller, model, or any view open:
    
* `:Ccontroller` to open to the associated controller.

* `:Cmodel` to open to the associated model.

* `:Cview` to open the associated view directory in a file browser.

You can also run these with an argument:

* `:Ccontroller [name]` to open the specified controller.

* `:Cmodel [name]` to open the specified model.

* `:Cview [name]` to open the specified and associated view file.

For these to work, you need to use the Cake MVC name conventions (i.e. If the
model name is `post.php`, the controller should be `posts_controller.php` and any 
views should be located under `views/posts`.)

Again, see [doc/cakephp.vim](https://github.com/ndreynolds/vim-cakephp/blob/master/doc/cakephp.txt) for the full documentation.
