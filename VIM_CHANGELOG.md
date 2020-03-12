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
