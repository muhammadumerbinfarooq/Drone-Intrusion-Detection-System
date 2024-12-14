section .data
    filename db 'drone_activity.log', 0
    buffer_size equ 1024
    buffer times buffer_size db 0
    pattern db 'unauthorized_access', 0
    pattern_len equ $ - pattern
    encryption_key db 'my_secret_key', 0
    key_len equ $ - encryption_key

section .bss
    file_descriptor resb 4
    bytes_read resb 4
    thread_id resb 4

section .text
    global _start

_start:
    ; Open the log file
    mov eax, 5          ; sys_open
    mov ebx, filename   ; filename
    mov ecx, 0          ; O_RDONLY
    int 0x80            ; syscall
    mov [file_descriptor], eax

    ; Check if file opened successfully
    cmp eax, 0
    js _exit

    ; Create a thread for reading the log file
    mov eax, 2          ; sys_fork
    int 0x80            ; syscall
    cmp eax, 0
    je _read_loop       ; Child process
    jg _parent_process  ; Parent process

_read_loop:
    ; Read the log file
    mov eax, 3          ; sys_read
    mov ebx, [file_descriptor]
    mov ecx, buffer
    mov edx, buffer_size
    int 0x80            ; syscall
    mov [bytes_read], eax

    ; Check if end of file
    cmp eax, 0
    je _close_file

    ; Analyze the buffer for unauthorized access patterns
    mov esi, buffer
    mov edi, pattern
    mov ecx, buffer_size
    call find_pattern

    ; Encrypt the buffer
    mov esi, buffer
    mov edi, encryption_key
    mov ecx, buffer_size
    call encrypt_buffer

    ; Continue reading the file
    jmp _read_loop

_close_file:
    ; Close the file
    mov eax, 6          ; sys_close
    mov ebx, [file_descriptor]
    int 0x80            ; syscall

_exit:
    ; Exit the program
    mov eax, 1          ; sys_exit
    xor ebx, ebx
    int 0x80            ; syscall

_parent_process:
    ; Parent process waits for the child to finish
    mov eax, 7          ; sys_waitpid
    mov ebx, -1
    mov ecx, 0
    int 0x80            ; syscall
    jmp _exit

find_pattern:
    ; Find the pattern in the buffer
    push esi
    push edi
    push ecx

    mov edx, pattern_len
_find_loop:
    mov al, [esi]
    cmp al, [edi]
    jne _next_byte

    ; Check if the entire pattern matches
    mov ecx, edx
    repe cmpsb
    je _pattern_found

_next_byte:
    inc esi
    loop _find_loop

    ; Pattern not found
    pop ecx
    pop edi
    pop esi
    ret

_pattern_found:
    ; Pattern found, handle it (e.g., log, alert)
    ; For simplicity, we'll just exit
    mov eax, 1          ; sys_exit
    xor ebx, ebx
    int 0x80            ; syscall

encrypt_buffer:
    ; Simple XOR encryption for demonstration
    push esi
    push edi
    push ecx

_encrypt_loop:
    mov al, [esi]
    xor al, [edi]
    mov [esi], al
    inc esi
    inc edi
    loop _encrypt_loop

    pop ecx
    pop edi
    pop esi
    ret
