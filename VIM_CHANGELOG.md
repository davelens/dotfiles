# (n)vim changelog
> [This is my vimrc](https://github.com/davelens/dotfiles/blob/master/vimrc). There are many like it, but this one is mine.
> My vimrc is my best friend. It is my life. I must master it as I must master my life.
> Without me, my vimrc is useless. Without my vimrc, I am useless.

In an average week of work I see a lot of code. Over the years I've learned to read it much like the operators as seen in [The Matrix](https://en.wikipedia.org/wiki/The_Matrix): I can interpret context (and sometimes, intent) quickly as I'm skimming it, line after line. It made me a better programmer and allows me to learn quickly from "new code".

Sadly, I'm also somewhat forgetful of random pieces of information: What I ate the day before, what the current date is, when I worked on a particular feature in a project, etc,...  This is often annoying when an undocumented line in my vimrc sits there for years and I can only vaguely remember why I put it there. 

An experiment then. With this file I hope to keep a contextualized overview of 
all my Vim changes as time goes by. This way I can follow the reasoning of past 
Dave and hopefully make appropriate decisions when performing future revisions
of my beloved `.vimrc`. There are many like it, but this one's mine.

## (n)vim TODOs
I'll try out GitHub issues to maintain a TODO list [here]( https://github.com/davelens/dotfiles/issues?q=is%3Aopen+label%3Atodo+label%3Avim).

## 2020-04-02
* In review of my changes of 31/3, I removed my homebrew testing functionality in favour of `vim-dispatch` and `vim-test`. They work together beautifully.  I realised I wrote the functionality for running a single test file was written mostly because I wanted to get some practice in with vimscript problem solving. In the end, I came up with a solution that was dependent on nvim_* methods. This is OK, as I'm using neovim at the moment because it's faster, but I'm unsure how my stance on neovim will change in the future. Vim has been around for 30 odd years, chances are it'll be here the next 30, too. Not so sure about neovim. Time will tell. Regardless, Tim Pope is a bonafide genius.
* Removed my `]q` and `[q` maps in favour of `vim-unimpaired`. I want to make use of its linewise and {en,de}coding maps.
* Added `:SV`, short for`source ~/.vimrc`. I just do it too much lately.
* Let `RenameFile()` use `:Grename` whenever a `.git` directory is present.

## 2020-04-01
* No jokes.

## 2020-03-31
* Slightly adjusted my previous `<CR>` unmapping when entering command-line mode to include `<C-W>p` so my cursor position is retained in the current buffer when running tests.
* Extended said unmapping to run on both `TermOpen` and `TermClose`. This is so other terminal windows do not receive the `<CR>` override.
* Prefixed said unmapping to perform silently so that we don't have vim whining about non-existent bindings.
* Added `DeleteHiddenBuffers()`. Because I'm experimenting with how I expect my terminal windows to behave when triggered by `RunTestFile()`, I looked for a solution that would wipe out all but my currently visible buffers to free up some memory. As an aside it *might* be useful if there are plenty of buffers open and you want to regain some clarity without exiting Vim. To be reviewed on a later date.
* I actively started documenting specific settings in my vimrc, both as a re-evaluation of why they're there, and as a learning opportunity to dig deeper in their `:help` entries.
* Added a better configuration to make `autoread` also catch changes made from outside of vim (or in my case specifically; another instance of vim in a tmux session). I was wondering why autoread didn't do what I thought it did, so I read up on it and found a great summary [here](https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044).
* Calling `RunTestFile()` with `<CR>` now opens up a terminal at the bottom to run my command in. This is an attempt to mimic vim-dispatch's functionality, but speedier. It also autocloses the terminal window when no test errors occurred, without losing freedom of movement in my active buffer. It does not place your test errors in quickfix (arguably preferable), but this will do for now.

## 2020-03-30
* I now unmap `<CR>` (normally mapped to `RunTestFile()`) whenever I enter command-line mode, so I can use `<CR>` to run the command under the cursor. I remap it whenever I leave command-line mode.

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
