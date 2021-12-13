if !exists('g:__vital_Neon_neons')
  let g:__vital_Neon_neons = {}
endif
let s:MAXPOSMATCH = 8
let s:DELETE_CONTEXT_FINISHED = 0
let s:DELETE_CONTEXT_WINCLOSED = 1
let s:DELETE_CONTEXT_MANUAL = 2




function s:add(unnormalized_flow, target, options = {}) abort
  let options = extend({'window': 0, 'repeat': 1, 'priority': 10}, a:options)

  let neon = {}
  let neon.flow = s:_normalize_flow(a:unnormalized_flow)
  if empty(neon.flow)
    throw 'vital: Neon: Invalid flow: ' .. string(a:unnormalized_flow)
  endif
  let neon.flow_len = len(neon.flow)
  if options.repeat == 0
    throw 'vital: Neon: Repeat option must be a non-zero number: ' .. options.repeat
  endif
  let neon.repeat = options.repeat
  let neon.id = s:_allocate_neon_id()
  let neon.temp_hl_group = 'VitalNeon' .. neon.id
  " To avoid "E28: No such highlight group name: FooBar" error.
  execute 'highlight clear' neon.temp_hl_group
  let neon.match_ids = s:_matches_add(
        \   neon.temp_hl_group, a:target,
        \   options.priority, -1,
        \   s:_pick(options, ['window', 'conceal']),
        \ )
  let neon.winid = s:_ensure_winid(options.window)
  let neon.timer = -1
  if has_key(options, 'callback')
    let neon.callback = options.callback
  endif
  let g:__vital_Neon_neons[neon.id] = neon

  call s:_tick(neon, 0)
  call s:_define_WinClosed_autocmd(neon.id, neon.winid)

  return neon.id
endfunction




" This causes "E121: Undefined variable: s:DELETE_CONTEXT_MANUAL" error.
" function s:delete(neon_id, context = s:DELETE_CONTEXT_MANUAL) abort
execute 'function s:delete(neon_id, context = ' .. s:DELETE_CONTEXT_MANUAL .. ') abort'
  if !has_key(g:__vital_Neon_neons, a:neon_id)
    throw 'vital: Neon: ID not found: ' .. a:neon_id
  endif

  call s:_delete(a:neon_id, a:context)
endfunction




function s:clear_all() abort
  for neon_id in keys(g:__vital_Neon_neons)
    call s:_delete(neon_id)
  endfor
endfunction




function s:_tick(neon, tick) abort
  let [hl_group, duration] = a:neon.flow[a:tick % a:neon.flow_len]
  execute 'highlight link' a:neon.temp_hl_group hl_group

  if duration < 0
    let a:neon.timer = -1
    return
  endif

  let l:Callback = a:tick + 1 == a:neon.flow_len * a:neon.repeat
        \ ? { -> s:_delete(a:neon.id, s:DELETE_CONTEXT_FINISHED) }
        \ : { -> s:_tick(a:neon, a:tick + 1) }
  let a:neon.timer = timer_start(duration, l:Callback)
endfunction




function s:_define_WinClosed_autocmd(neon_id, winid) abort
  execute 'augroup vital-Neon-delete-' .. a:neon_id
    autocmd!
    execute 'autocmd WinClosed' a:winid '++nested ++once'
          \ 'call s:_delete(' .. a:neon_id .. ', s:DELETE_CONTEXT_WINCLOSED)'
  augroup END
endfunction




function s:_delete_WinClosed_autocmd(neon_id) abort
  execute 'autocmd! vital-Neon-delete-' .. a:neon_id
  execute 'augroup! vital-Neon-delete-' .. a:neon_id
endfunction




" - Must be called with valid neon id.
" - If second optional argument is given and the neon has a callback, the
"   callback is called with the argument.
function s:_delete(neon_id, ...) abort
  let neon = remove(g:__vital_Neon_neons, a:neon_id)
  call s:_delete_WinClosed_autocmd(neon.id)
  call timer_stop(neon.timer)
  for match_id in neon.match_ids
    call s:_matchdelete_safe(match_id, neon.winid)
  endfor
  execute 'highlight clear' neon.temp_hl_group

  if a:0 == 0 || !has_key(neon, 'callback')
    return
  endif

  try
    call neon.callback(neon.id, a:1)
  catch
    let fmt = 'vital: Neon: ' ..
          \   'Error detected while executing a neon callback: [%s] %s'
    call s:_echoerr(printf(fmt, v:throwpoint, v:exception))
  endtry
endfunction




function s:_normalize_flow(flow) abort
  let normalized_flow = []
  for pair in a:flow
    if pair[1] == 0
      continue
    endif
    let normalized_flow += [pair]
    if pair[1] < 0
      break
    endif
  endfor
  return normalized_flow
endfunction




function s:_allocate_neon_id() abort
  let neon_id = 1
  while has_key(g:__vital_Neon_neons, neon_id)
    let neon_id += 1
  endwhile
  return neon_id
endfunction




function s:_matches_add(hl_group, target, priority, id, dict) abort
  if type(a:target) == v:t_string
    return [matchadd(a:hl_group, a:target, a:priority, a:id, a:dict)]
  elseif type(a:target) == v:t_list
    return map(range(0, len(a:target) - 1, s:MAXPOSMATCH),
          \ { _, i -> matchaddpos(a:hl_group, a:target[i : i + s:MAXPOSMATCH - 1], a:priority, a:id, a:dict) })
  endif
  throw 'vital: Neon: Target must be a String or a List: ' .. string(a:target)
endfunction




" Same as built-in matchdelete(), but stub out "E803: ID not found: 123" error.
function s:_matchdelete_safe(match_id, winid) abort
  try
    call matchdelete(a:match_id, a:winid)
  catch /^Vim(call):E803:/
  endtry
endfunction




function s:_ensure_winid(n) abort
  if a:n == 0
    return win_getid()
  elseif 1 <= a:n && a:n <= winnr('$')
    return win_getid(a:n)
  else
    return a:n
  endif
endfunction




function s:_pick(dict, keys) abort
  let new_dict = {}
  for key in a:keys
    if has_key(a:dict, key)
      let new_dict[key] = a:dict[key]
    endif
  endfor
  return new_dict
endfunction




function s:_echoerr(msg) abort
  echohl ErrorMsg
  echomsg a:msg
  echohl None
endfunction
