# (n)vim changelog
> [This is my vimrc](https://github.com/davelens/dotfiles/blob/master/vimrc). There are many like it, but this one is mine.
> My vimrc is my best friend. It is my life. I must master it as I must master my life.
> Without me, my vimrc is useless. Without my vimrc, I am useless.

In an average week of work I see several thousands lines of code. I can maintain
a hyperfocus on certain programmatical problems during my day job and it allows
me to learn quickly from "new code" as I'm skimming it. Sadly, I'm also somewhat
forgetful of random pieces of information: What I ate the day before, what the current date is, when I worked on a particular feature in a project, etc,...

This is often annoying when an undocumented line in my vimrc sits there for years and I can only vaguely remember why I put it there. 

An experiment then. With this file I hope to keep a contextualized overview of 
all my Vim changes as time goes by. This way I can follow the reasoning of past 
Dave and hopefully make appropriate decisions when performing future revisions
of my beloved `.vimrc`. There are many like it, but this one's mine.

## (n)vim TODOs
I'll try out GitHub issues to maintain a TODO list [here]( https://github.com/davelens/dotfiles/issues?q=is%3Aopen+label%3Atodo+label%3Avim).

## 2020-03-26
* Added `<leader>d` in normal+visual mode to trigger definition lookup in Ruby files using `:Rg`. Just for those times when I can't use vim-rails's `gf`.
* Added `<leader>x` in normal mode to close the current file without saving. The reason I added this is because I had a brainwave and realised why my `tnoremap <leader>x` did not work: Normal mode persists in terminal windows! I was overthinking the window's constraints. So now closing a file or a terminal can benefit from the same mapping.

## 2020-03-23
* Added `set inccommand=split` to show substitution results in a preview window. A setting I wasn't aware of, but is entirely convenient.

## 2020-03-14
* Added a nmap for `\` to trigger a Rg search for Ruby method definitions in the active buffer window. I was planning on making this Ruby agnostic (which you can do by replacing `"def "` with `""` in the map), but it would require you to type `'def '` in the subsequent search field. I tried this out for a colleague and will probably not use it much (I still think typing `/def ` and `n` to cycle through definitions is faster).

## 2020-03-13
* Added a fix to copy stuff straight into the system clipboard on WSL. I have a Windows desktop at home (my "hobby machine") with WSL installed. I do some programming there on occasion as well, so a similar copy/paste functionality compared to my regular macos setup is handy.
* Added a way to look up I18n translation strings by their identifier from within Vim. Sometimes I'm coming back to a partial for a refactor or a feature, and knowing what text certain `I18n.t` calls hold without looking them up manually is handy. This approach would make it possible (with some revision) to get a list of untranslated strings across all partials from within Vim, too.

## 2020-03-11
* Added `g:rails_gem_projections` configuration for the [draper](https://github.com/drapergem/draper) gem. The FactoryBot mappings I made yesterday along with the `:A`/`:R` bindings are an improvement, so I added this after wanting to jump to a decorator file.

## 2020-03-10

* Added a vim changelog. \o/
* Replaced `OpenGem()` in favor of Tim Pope's [vim-bundler](https://github.com/tpope/vim-bundler), mapping `<leader>g` to 
its `:Bopen` command. I now rely on this plugin to do my heavy lifting when browsing gems.
* Replaced `ConvertCamelCaseToSnakeCase()` function in favor of Time Pope's [vim-abolish](https://github.com/tpope/vim-abolish). Its `crs` motion does the same thing, and I get to use all its  other coercions to convert to any other kind of casing I want. Also, this method name was faulty, as it should've been `ConvertMixedCaseToSnakeCase()` instead.
* Removed apidock.vim configuration, as it's been gone for a good while now.
* Removed `SaveAndRefreshFirefox()`, I haven't used it in years.
* Removed `<leader>r` mapping in favor of [vim-rails](https://github.com/tpope/vim-rails)'s `:A`. It offers more useful 
Rails-specific alternatives.
* Added `<leader>a` mapping to vim-rails's `:A` (alternative file)
* Added `<leader>r` mapping to vim-rails's `:R` (relative file)
* Added `g:rails_gem_projections` configuration for the [factory_bot](https://github.com/thoughtbot/factory_bot) gem. I'd like to take more advantage of file jumps with more identifiers, ideally mapping out recurring gems in our company's Gemfiles. I'm planning on adding more when this one works well.
* Replaced the `RubyTestCommand()` call in `RunRubyTests()` with plain `bundle exec rspec`. I had a strange problem with certain tests involving routes failing because they added a `?locale=nl` parameter. Running a bundled rspec did not (and should not!) throw these errors.
* Added a `:Terminal` command that opens up a terminal across the full width at the bottom, slightly smaller than your average split. It's mapped to `<leader>b` (b for "bottom"). I might remap this to `<leader>bt` ("bottom terminal") if I ever find a better use for "b".
