
%macro  exit 1
        mov     rax, 60
        mov     rdi, %1
        syscall
%endmacro

%macro  print   2
        mov     rax, 1          ;SYS_write
        mov     rdi, 1          ;standard output device
        mov     rsi, %1         ;output string address
        mov     rdx, %2         ;number of character
        syscall           ;calling system services
%endmacro

%macro  scan  2
        mov     rax, 0          ;SYS_read
        mov     rdi, 0          ;standard input device
        mov     rsi, %1         ;input buffer address
        mov     rdx, %2         ;number of character
        syscall           ;calling system services
%endmacro

; Initialized (nonzero) stuff
section .data
operator db '+'

; Read only stuff
section .rodata
hello db "Enter an equation:", 10, 0
hello_sz equ $ - hello - 1

equals_msg db " = "
equals_sz equ $ - equals_msg

newline db 10, 0
newline_sz equ $ - newline - 1

; Zero initialized stuff
section .bss
value resb 1
incoming resb 1
buffer resb 16

; Instructions go into .text section
section .text

; The linker needs to find the entry point, so it must be global
; The linker assumes the entry point is _start if you
; don't tell it another name to use
global _start
_start:
    ; Print the welcome message
    ; that asks them to enter an equation
  print hello, hello_sz

    ; Read the user input, up to 10 bytes or until enter
  scan buffer, 10
    dec rax
    push rax

    ; Echo the message the entered back
    ; we pushed the size above so we can
    ; get the macro to fetch it (it is scary to assume we
    ; know what registers the macro overwrites)
    print buffer,[rsp]

    ; Undo the storage of the size above
    ; (pop smaller than adding to rsp)
    pop rax

    ; Print the little equals string
    print equals_msg, equals_sz

    ; Point to the start of the buffer
    lea rbx,[buffer]

;Loop through each character in the buffer
another_char:
    ; Get the next byte into eax
    movzx eax,byte [rbx]

    ; Check for newline (ASCII 10)
    cmp al,10
    je show_result

    cmp al, '0'
    jb not_digit
    cmp al, '9'
    ja not_digit
    ; It is a digit

    ; Get decimal value of character into al '4' -> 4
    sub al,'0'
    mov [incoming],al

    ; See what the current operator is
    mov cl,[operator]
    cmp cl,'+'
    je do_add
    cmp cl,'-'
    je do_subtract
    cmp cl,'*'
    je do_multiply
    cmp cl,'/'
    je do_divide
    ; Should not reach here
    jmp done

do_add:
    mov al,[incoming]
    add [value],al
    jmp next_char

do_subtract:
    mov al,[incoming]
    sub [value],al
    jmp next_char

do_multiply:
    movzx ax,[incoming]
    movzx cx,[value]
    mul cx
    mov [value],al
    jmp next_char

do_divide:
    mov dx, 0
    movzx ax,[value]
    movzx cx,[incoming]
    div cx
    mov [value],al
    ;jmp next_char

next_char:
    add rbx,1
    cmp byte[rbx],0
    jne another_char
    jmp show_result

not_digit:
    ; Is it plus
    cmp al, '+'
    je plus
    ; Is it minus
    cmp al, '-'
    je minus
    ; is it multiply
    cmp al, '*'
    je multiply
    ; is it divide
    cmp al, '/'
    je divide

    ; should not reach here - just bomb out
    jmp done

plus:
    mov byte [operator],'+'
    jmp next_char

minus:
    mov byte [operator],'-'
    jmp next_char

divide:
    mov byte [operator],'/'
    jmp next_char

multiply:
    mov byte [operator],'*'
    jmp next_char

show_result:
    mov al,byte [value]
    add al,'0'
    mov [buffer],al
    mov byte [buffer+1],0

    print buffer,1

    print newline,1

done:
    exit 0


