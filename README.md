<div align="center">
  <img width="600" alt="vital-Neon logo" src="https://user-images.githubusercontent.com/64692680/142174631-5279bb54-b294-4de9-b2c2-e3c179b1d7ce.png">

  A [vital](https://github.com/vim-jp/vital.vim) module to highlight text dynamically.
</div>


## Requirements

- [Vim 8.2.3591](https://github.com/vim/vim/commit/23beefed73aadb243fb67cf944e3d60fe8c038bb) or later
- [vital.vim](https://github.com/vim-jp/vital.vim)


## Usage

### Blink text that matches a specified pattern

```vim
let s:blink_flow = [
      \   ['DiffDelete', 300],
      \   ['NONE', 300],
      \ ]
call s:Neon.add(s:blink_flow, '\[\zs[^]]*\ze\],', {'repeat': -1})
```

![demo-blink](https://user-images.githubusercontent.com/64692680/142168601-24aa0fc3-1bd8-4508-a4a2-5a98f55754f4.gif)


### Create a mapping that glows the cursor line

```vim
highlight MyGlow1 ctermbg=236 guibg=#161821
highlight MyGlow2 ctermbg=237 guibg=#222428
highlight MyGlow3 ctermbg=238 guibg=#2e3130
highlight MyGlow4 ctermbg=239 guibg=#393d37
highlight MyGlow5 ctermbg=240 guibg=#45493e
let s:glow_flow = [
      \   ['MyGlow1', 200],
      \   ['MyGlow2', 200],
      \   ['MyGlow3', 200],
      \   ['MyGlow4', 200],
      \   ['MyGlow5', -1],
      \ ]
function s:glow_cursorline() abort
  let cursorlnum = line('.')
  call s:Neon.add(s:glow_flow, [cursorlnum])
endfunction
nnoremap <F7> <Cmd>call <SID>glow_cursorline()<CR>
```

![demo-glow](https://user-images.githubusercontent.com/64692680/142169702-c8fd5272-673a-44e6-8c56-d562e6ab0888.gif)


### Create a mapping that flashes the lines indented by `=` operator

```vim
highlight MyFlash1 ctermbg=240 guibg=#384851
highlight MyFlash2 ctermbg=239 guibg=#303c45
highlight MyFlash3 ctermbg=238 guibg=#273039
highlight MyFlash4 ctermbg=237 guibg=#1f242d
highlight MyFlash5 ctermbg=236 guibg=#161821
let s:flash_flow = [
      \   ['MyFlash1', 50],
      \   ['MyFlash2', 50],
      \   ['MyFlash3', 50],
      \   ['MyFlash4', 50],
      \   ['MyFlash5', 50],
      \ ]
function s:set_operatorfunc() abort
  let &operatorfunc = get(funcref('s:hl_indent'), 'name')
  return ''
endfunction
function s:hl_indent(_) abort
  normal! =g']
  call s:Neon.add(s:flash_flow, range(line("'["), line("']")))
endfunction
nnoremap <expr> = <SID>set_operatorfunc() .. 'g@'
xnoremap <expr> = <SID>set_operatorfunc() .. 'g@'
```

![demo-flash](https://user-images.githubusercontent.com/64692680/142171837-e95f3db0-75be-4a80-aafe-4af682a8337f.gif)


## License

[NYSL Version 0.9982](LICENSE)
