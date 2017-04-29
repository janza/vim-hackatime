" ============================================================================
" File:        wakatime.vim
" Description: Automatic time tracking for Vim.
" Maintainer:  WakaTime <support@wakatime.com>
" License:     BSD, see LICENSE.txt for more details.
" Website:     https://wakatime.com/
" ============================================================================

let s:VERSION = '4.0.15'


" Init {{{

    " Check Vim version
    if v:version < 700
        echoerr "This plugin requires vim >= 7."
        finish
    endif

    " Use constants for truthy check to improve readability
    let s:true = 1
    let s:false = 0

    " Only load plugin once
    if exists("g:loaded_wakatime")
        finish
    endif
    let g:loaded_wakatime = s:true

    " Backup & Override cpoptions
    let s:old_cpo = &cpo
    set cpo&vim

    " Script Globals
    let s:home = expand("$WAKATIME_HOME")
    if s:home == '$WAKATIME_HOME'
        let s:home = expand("$HOME")
    endif
    let s:cli_location = expand("<sfile>:p:h") . '/logtime.py'
    let s:data_file = s:home . '/.wakatime.data'
    let s:local_cache_expire = 10  " seconds between reading s:data_file
    let s:last_heartbeat = [0, 0, '']

    " Set default python binary location
    if !exists("g:wakatime_PythonBinary")
        let g:wakatime_PythonBinary = 'python'
    endif

    " Set default heartbeat frequency in minutes
    if !exists("g:wakatime_HeartbeatFrequency")
        let g:wakatime_HeartbeatFrequency = 2
    endif

    " Set default influx db hostname
    if !exists("g:wakatime_InfluxHost")
        let g:wakatime_InfluxHost = ''
    endif

    " Set default influx db basic auth header
    if !exists("g:wakatime_BasicAuth")
        let g:wakatime_BasicAuth = ''
    endif

" }}}


" Function Definitions {{{

    function! s:StripWhitespace(str)
        return substitute(a:str, '^\s*\(.\{-}\)\s*$', '\1', '')
    endfunction

    function! s:GetCurrentFile()
        return expand("%:p")
    endfunction

    function! s:EscapeArg(arg)
        return substitute(shellescape(a:arg), '!', '\\!', '')
    endfunction

    function! s:JoinArgs(args)
        let safeArgs = []
        for arg in a:args
            let safeArgs = safeArgs + [s:EscapeArg(arg)]
        endfor
        return join(safeArgs, ' ')
    endfunction

    function! s:SendHeartbeat(file, time, is_write, last)
        let file = a:file
        if file == ''
            let file = a:last[2]
        endif
        if file != '' && g:wakatime_BasicAuth != '' && g:wakatime_InfluxHost != ''
            let python_bin = g:wakatime_PythonBinary
            let cmd = [s:cli_location]
            let cmd = cmd + ['--entity', file]
            let cmd = cmd + ['--auth', g:wakatime_BasicAuth]
            let cmd = cmd + ['--host', g:wakatime_InfluxHost]
            try
                let cmd = cmd + ['--project', fnamemodify(expand(fugitive#buffer().repo().tree()), ":t")]
            catch
            endtry

            try
                let cmd = cmd + ['--branch', fugitive#head()]
            catch
            endtry
            if a:is_write
                let cmd = cmd + ['--write']
            endif
            if !empty(&syntax)
                let cmd = cmd + ['--language', &syntax]
            else
                if !empty(&filetype)
                    let cmd = cmd + ['--language', &filetype]
                endif
            endif
            if v:version >= 800
                call job_start(s:JoinArgs(cmd))
            elseif has('nvim')
                call jobstart(s:JoinArgs(cmd))
            else
                call system(s:JoinArgs(cmd))
            endif
            call s:SetLastHeartbeat(a:time, a:time, file)
        endif
    endfunction

    function! s:GetLastHeartbeat()
        if !s:last_heartbeat[0] || localtime() - s:last_heartbeat[0] > s:local_cache_expire
            if !filereadable(s:data_file)
                return [0, 0, '']
            endif
            let last = readfile(s:data_file, '', 3)
            if len(last) == 3
                let s:last_heartbeat = [s:last_heartbeat[0], last[1], last[2]]
            endif
        endif
        return s:last_heartbeat
    endfunction

    function! s:SetLastHeartbeatLocally(time, last_update, file)
        let s:last_heartbeat = [a:time, a:last_update, a:file]
    endfunction

    function! s:SetLastHeartbeat(time, last_update, file)
        call s:SetLastHeartbeatLocally(a:time, a:last_update, a:file)
        call writefile([substitute(printf('%d', a:time), ',', '.', ''), substitute(printf('%d', a:last_update), ',', '.', ''), a:file], s:data_file)
    endfunction

    function! s:EnoughTimePassed(now, last)
        let prev = a:last[1]
        if a:now - prev > g:wakatime_HeartbeatFrequency * 60
            return s:true
        endif
        return s:false
    endfunction

" }}}


" Event Handlers {{{

    function! s:handleActivity(is_write)
        let file = s:GetCurrentFile()
        let now = localtime()
        let last = s:GetLastHeartbeat()
        if !empty(file) && file !~ "-MiniBufExplorer-" && file !~ "--NO NAME--" && file !~ "^term:"
            if a:is_write || s:EnoughTimePassed(now, last) || file != last[2]
                call s:SendHeartbeat(file, now, a:is_write, last)
            else
                if now - s:last_heartbeat[0] > s:local_cache_expire
                    call s:SetLastHeartbeatLocally(now, last[1], last[2])
                endif
            endif
        endif
    endfunction

" }}}


" Autocommand Events {{{

    augroup Wakatime
        autocmd!
        autocmd BufEnter * call s:handleActivity(s:false)
        autocmd VimEnter * call s:handleActivity(s:false)
        autocmd BufWritePost * call s:handleActivity(s:true)
        autocmd CursorMoved,CursorMovedI * call s:handleActivity(s:false)
    augroup END

" }}}



" Restore cpoptions
let &cpo = s:old_cpo
