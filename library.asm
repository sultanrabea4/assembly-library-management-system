section .data
    ; Menu Display
    menu db 'Library Management System',0xA
         db '---------------------------------',0xA
         db '1- Add a Book',0xA
         db '2- Search for a Book',0xA
         db '3- Display All Books',0xA
         db '4- Borrow a Book',0xA
         db '5- Display All Borrows',0xA
         db '6- Exit',0xA
         db '---------------------------------',0xA
         db 'Enter your choice: ',0
    len equ $ - menu

    ; Messages
    thanks_msg db 'Thank you for using Library Management System!',0
    len_thanks equ $ - thanks_msg

    fail_msg db 'Operation failed!',0xA,0
    success_msg db 'Operation successful!',0xA,0
    book_added_msg db "Book added successfully!", 0xA, 0
    book_exists_msg db "Book already exists!", 0xA, 0
    book_not_found_msg db 'Book not found!',0xA,0  
    book_borrowed_msg db 'Book borrowed successfully!', 0xA, 0
    book_returned_msg db 'Book returned successfully!', 0xA, 0
    invalid_input_msg db "Invalid choice, please try again.", 0xA, 0

    ; User Prompts
    add_book_title_msg db 'Enter Book Title: ',0
    add_book_author_msg db 'Enter Author Name: ',0
    remove_book_msg db 'Enter Book Title to Remove: ',0
    search_book_msg db 'Enter Book Title to Search: ',0
    enter_book_msg db "Enter book name: ", 0
    enter_author_msg db "Enter author name: ", 0
    borrow_name_msg db 'Enter Borrower Name: ',0
    borrow_phone_msg db 'Enter Phone Number: ',0
    borrow_book_msg db 'Enter Book Title to Borrow: ',0
    borrow_date_msg db 'Enter Date (DD/MM/YYYY): ',0
    return_name_msg db 'Enter Borrower Name: ',0
    return_phone_msg db 'Enter Phone Number: ',0
    return_book_msg db 'Enter Book Title to Return: ',0
    return_date_msg db 'Enter Return Date (DD/MM/YYYY): ',0

    ; Labels & Separators
    separator db '-----------------------',0xA,0  ; Define separator only once
    space_separator db " ", 0
    newline db 10, 0
    book_name_label db 'Book Name: ',0
    author_name_label db 'Author Name: ',0
    borrower_name_label db 'Borrower Name: ',0
    phone_label db 'Phone Number: ',0
    borrow_date_label db 'Date: ',0
    delimiter db '|',0

    ; Files
    books_filename db "books.txt", 0  
    borrowed_filename db "borrow.txt", 0
    temp_filename db "temp.txt", 0

    ; Header for display
    header db 'Title          | Author', 0xA, 0
    padding db '     ', 0  ; Adjust padding as needed


section .bss
    ; User choice
    choice resb 2  

    ; Book-related variables
    book_title resb 100  
    book_author resb 100  
    book_name resb 100  
    author_name resb 100  
    search_title resb 100  

    ; Borrowing-related variables
    borrower_name resb 100  
    borrower_phone resb 20  
    borrow_title resb 100  
    borrow_date resb 20  
    borrow_buffer resb 256  

    ; File handling
    temp_buffer resb 256  
    read_buffer resb 256  
    file_descriptor resd 1  ; Changed from resq to resd
    temp_file_descriptor resd 1  ; Changed from resq to resd
    borrowed_file_descriptor resd 1  ; Changed from resq to resd

    ; Flags
    book_found resb 1  



section .text
global _start

trim_newline:
    test edi, edi        ; Check if edi is NULL
    jz .done             ; If NULL, exit function
    cmp byte [edi], 0    ; Check if string is empty
    je .done
.loop:
    cmp byte [edi], 10   ; Check for newline character (LF = 0x0A)
    je .replace
    cmp byte [edi], 0    ; Stop at null terminator
    je .done
    inc edi
    jmp .loop
.replace:
    mov byte [edi], 0    ; Replace newline with null terminator
.done:
    ret

; =================================================
; STRING COMPARE FUNCTION
; Input: edi = first string, esi = second string
; Output: al = 1 if equal, 0 if not equal
; =================================================
string_compare:
    push ebx
    push ecx

    xor ecx, ecx        ; Initialize counter

.compare_loop:
    mov al, byte [edi + ecx]  ; Load character from first string
    mov bl, byte [esi + ecx]  ; Load character from second string
    
    ; Check if characters are different
    cmp al, bl
    jne .strings_different
    
    ; Check if we've reached the end of both strings
    cmp al, 0
    je .strings_equal
    
    inc ecx
    jmp .compare_loop
    
.strings_equal:
    mov al, 1           ; Strings are equal
    jmp .compare_done
    
.strings_different:
    mov al, 0           ; Strings are not equal
    
.compare_done:
    pop ecx
    pop ebx
    ret


_start:
    ; Display the menu
    mov eax, 4          ; syscall: write
    mov ebx, 1          ; stdout
    mov ecx, menu
    mov edx, len
    int 0x80

    ; Read user choice
    mov eax, 3          ; syscall: read
    mov ebx, 0          ; stdin
    mov ecx, choice
    mov edx, 2
    int 0x80
    
    ; Check if read was successful
    cmp eax, 0
    jle _start  ; If error, show menu again
    
    ; Null-terminate the input
    mov byte [choice + eax], 0
    
    ; Check if newline was read
    cmp eax, 2
    jne invalid_input  ; If not exactly 2 bytes (digit + newline), invalid
    
    ; Compare user input and jump to the correct function
    mov al, [choice]
    cmp al, '1'
    je add_book
    cmp al, '2'
    je search_book
    cmp al, '3'
    je display_books
    cmp al, '4'
    je borrow_book
    cmp al, '5'
    je display_borrows
    cmp al, '6'
    je exit_program
    
    ; If we get here, it's an invalid choice
    jmp invalid_input

invalid_input:
    mov esi, invalid_input_msg
    call write_output
    jmp _start  ; Return to menu

write_output:
    push eax
    push edx
    push ebx

    ; Calculate string length
    mov edx, 0
    mov edi, esi
.loop:
    cmp byte [edi + edx], 0
    je .done
    inc edx
    jmp .loop
.done:
    mov eax, 4      ; syscall: write
    mov ebx, 1      ; stdout
    mov ecx, esi    ; String to write
    int 0x80

    pop ebx
    pop edx
    pop eax
    ret

read_input:
    push eax
    push ebx
    push ecx

    mov eax, 3      ; syscall: read
    mov ebx, 0      ; stdin
    mov ecx, esi    ; Buffer to read into
    int 0x80

    ; Handle error case
    cmp eax, 0
    jle .error

    ; Replace newline with null terminator
    mov ecx, eax    ; Save the number of bytes read
    dec ecx         ; Adjust for 0-indexing
    
    ; Check if the last character is a newline
    cmp byte [esi + ecx], 10
    jne .no_newline
    
    ; Replace newline with null
    mov byte [esi + ecx], 0
    jmp .done
    
.no_newline:
    ; Ensure null termination at the end
    mov byte [esi + eax], 0
    jmp .done
    
.error:
    ; On error, return empty string
    mov byte [esi], 0
    
.done:
    pop ecx
    pop ebx
    pop eax
    ret


write_to_file:
    push eax
    push edx
    push ebx
    push esi

    ; Ensure string is not empty
    cmp byte [esi], 0
    je .error

    ; Calculate string length
    mov edx, 0
    mov edi, esi
.find_length:
    cmp byte [edi + edx], 0
    je .done
    inc edx
    jmp .find_length
.done:
    mov eax, 4              ; syscall: write
    mov ebx, [file_descriptor]
    mov ecx, esi            ; String to write
    int 0x80
    jmp .exit

.error:
    mov esi, fail_msg
    call write_output

.exit:
    pop esi
    pop ebx
    pop edx
    pop eax
    ret


string_contains:
    ; edi = needle (search string)
    ; esi = haystack (buffer to search in)
    ; returns 1 in al if found, 0 if not found
    
    push ebx
    push ecx
    push edx
    
    ; First check if needle is empty
    cmp byte [edi], 0
    je .not_found
    
    ; Get length of needle
    mov ecx, 0
.count_needle:
    cmp byte [edi + ecx], 0
    je .search_loop
    inc ecx
    jmp .count_needle
    
.search_loop:
    mov edx, 0        ; Position in haystack
    
.outer_loop:
    cmp byte [esi + edx], 0
    je .not_found     ; End of haystack, not found
    
    mov ebx, 0        ; Position in needle
    
.compare_loop:
    mov al, byte [edi + ebx]
    cmp al, 0
    je .found         ; End of needle, we found a match

    lea eax, [esi + edx]  ; Calculate address
    add eax, ebx          ; Add offset
    mov al, byte [eax]    ; Get character
    cmp al, 0
    je .not_found     ; End of haystack in the middle of a comparison
    
    cmp al, byte [edi + ebx]
    jne .next_pos     ; Characters don't match, try next position
    
    inc ebx           ; Next character in needle
    jmp .compare_loop
    
.next_pos:
    inc edx           ; Try next position in haystack
    jmp .outer_loop
    
.found:
    mov al, 1
    jmp .done
    
.not_found:
    mov al, 0
    
.done:
    pop edx
    pop ecx
    pop ebx
    ret



append_string:
    push esi
    push edi

    ; Find end of destination string
    call find_end

.copy:
    mov al, [edi]
    cmp al, 0
    je .done
    mov [esi], al
    inc esi
    inc edi
    jmp .copy

.done:
    mov byte [esi], 0

    pop edi
    pop esi
    ret

find_end:
    push eax
.loop:
    cmp byte [esi], 0  ; Check if null terminator is reached
    je .done
    inc esi
    jmp .loop
.done:
    pop eax
    ret

append_to_file:
    push eax
    push ebx
    push ecx
    push edx
    push edi
    push esi

    ; Open file for appending
    mov eax, 5          ; syscall: open
    mov ecx, 0x202      ; O_RDWR | O_CREAT | O_APPEND
    mov edx, 0644o      ; mode
    int 0x80

    cmp eax, 0
    jl .done            ; If open fails, exit
    mov ebx, eax        ; File descriptor

    ; Write to file
    mov ecx, ebx        ; String to write
    call write_to_file

    ; Close file
    mov eax, 6          ; syscall: close
    int 0x80

.done:
    pop esi
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret


; =================================================
; ADD A BOOK
; =================================================

add_book:
    ; Ask for book title
    mov esi, enter_book_msg
    call write_output

    mov esi, book_title
    mov edx, 100
    call read_input
    mov edi, book_title
    call trim_newline

    ; Ask for author name
    mov esi, enter_author_msg
    call write_output

    mov esi, book_author
    mov edx, 100
    call read_input
    mov edi, book_author
    call trim_newline

    ; Open books.txt for appending
    mov eax, 5              ; syscall: open
    mov ebx, books_filename ; File name
    mov ecx, 0x402          ; O_RDWR | O_APPEND | O_CREAT
    mov edx, 0644o          ; Permissions: rw-r--r--
    int 0x80
    
    ; Check if file opened successfully
    cmp eax, 0
    jl add_book_failed
    
    mov [file_descriptor], eax  ; Store file descriptor

    ; Write book title
    mov esi, book_title
    call write_to_file

    ; Write delimiter
    mov esi, delimiter
    call write_to_file

    ; Write author name
    mov esi, book_author
    call write_to_file

    ; Write newline
    mov esi, newline
    call write_to_file

    ; Close file
    mov eax, 6              ; syscall: close
    mov ebx, [file_descriptor]
    int 0x80

    ; Success message
    mov esi, book_added_msg
    call write_output
    jmp _start

add_book_failed:
    ; Error message
    mov esi, fail_msg
    call write_output
    jmp _start


; =================================================
; DISPLAY BOOKS (FIXED)
; =================================================

display_books:
    ; Open the books file for reading
    mov eax, 5              ; syscall: open
    mov ebx, books_filename ; File name
    mov ecx, 0              ; O_RDONLY
    int 0x80
    
    ; Check if file opened successfully
    cmp eax, 0
    jl display_books_failed
    
    mov [file_descriptor], eax  ; Store file descriptor
    
    ; Track if any books were found
    mov byte [book_found], 0
    
    ; Print header
    mov esi, separator
    call write_output

    ; Print column headers
    mov esi, header
    call write_output
    mov esi, separator
    call write_output

display_books_loop:
    ; Clear read buffer
    xor eax, eax
    mov ecx, 64            ; Clear in 4-byte chunks (256/4 = 64)
    mov edi, read_buffer
    rep stosd
    
    ; Read a line from the file
    mov eax, 3              ; syscall: read
    mov ebx, [file_descriptor]
    mov ecx, read_buffer
    mov edx, 256            ; Read up to 256 bytes
    int 0x80

    ; Check if we reached the end of the file
    cmp eax, 0
    jle display_books_done

    ; Set flag indicating we found at least one book
    mov byte [book_found], 1
    
    ; Ensure null termination
    mov byte [read_buffer + eax], 0
    
    ; Print the book record
    mov esi, read_buffer
    call write_output

    ; Print a newline after the book record
    mov esi, newline
    call write_output

    ; Print separator after each book record
    mov esi, separator
    call write_output
    
    jmp display_books_loop

display_books_done:
    ; Close the file
    mov eax, 6              ; syscall: close
    mov ebx, [file_descriptor]
    int 0x80
    
    ; Check if no books were found
    cmp byte [book_found], 0
    jne display_books_success

    ; No books found, display a message
    mov esi, book_not_found_msg
    call write_output

display_books_success:
    jmp _start              ; Return to menu

display_books_failed:
    mov esi, fail_msg
    call write_output
    jmp _start


; =================================================
; SEARCH  BOOKS
; =================================================



search_book:
    ; Ask for book title to search
    mov esi, search_book_msg
    call write_output

    mov esi, search_title
    mov edx, 100
    call read_input
    mov edi, search_title
    call trim_newline

    ; Open books.txt for reading
    mov eax, 5              ; syscall: open
    mov ebx, books_filename
    mov ecx, 0              ; O_RDONLY
    int 0x80
    
    ; Check if file opened successfully
    cmp eax, 0
    jl search_failed
    
    mov [file_descriptor], eax

    ; Set book_found flag to 0
    mov byte [book_found], 0

search_loop:
    ; Read a line from books.txt
    mov eax, 3              ; syscall: read
    mov ebx, [file_descriptor]
    mov ecx, read_buffer
    mov edx, 256
    int 0x80

    ; Check for EOF or error
    cmp eax, 0
    jle search_done
    
    ; Null-terminate the buffer
    mov byte [read_buffer + eax], 0
    
    ; Check if the line contains the search title
    mov edi, search_title
    mov esi, read_buffer
    call string_contains
    
    ; Check result
    cmp al, 1
    je search_found
    
    jmp search_loop

search_found:
    ; Set book_found flag to 1
    mov byte [book_found], 1
    
    ; Display the found book record
    mov esi, read_buffer
    call write_output
    
    ; Add a newline
    mov esi, newline
    call write_output
    
    jmp search_loop  ; Continue searching for more matches

search_done:
    ; Close the file
    mov eax, 6              ; syscall: close
    mov ebx, [file_descriptor]
    int 0x80
    
    ; Check if any books were found
    cmp byte [book_found], 0
    je search_not_found
    
    ; Success message
    mov esi, success_msg
    call write_output
    jmp _start

search_not_found:
    mov esi, book_not_found_msg
    call write_output
    jmp _start

search_failed:
    mov esi, fail_msg
    call write_output
    jmp _start





; =================================================
; BORROW A BOOK 
; =================================================


borrow_book:
    ; Ask for borrower name
    mov esi, borrow_name_msg
    call write_output

    mov esi, borrower_name
    mov edx, 100
    call read_input
    mov edi, borrower_name
    call trim_newline

    ; Ask for phone number
    mov esi, borrow_phone_msg
    call write_output

    mov esi, borrower_phone
    mov edx, 20
    call read_input
    mov edi, borrower_phone
    call trim_newline

    ; Ask for book title
    mov esi, borrow_book_msg
    call write_output

    mov esi, borrow_title
    mov edx, 100
    call read_input
    mov edi, borrow_title
    call trim_newline

    ; Open books.txt for reading
    mov eax, 5              ; syscall: open
    mov ebx, books_filename
    mov ecx, 0              
    int 0x80
    cmp eax, 0
    jl borrow_book_failed  

    mov [file_descriptor], eax  

borrow_search_loop:
    ; Clear read buffer
    xor eax, eax
    mov ecx, 64            ; Clear in 4-byte chunks (256/4 = 64)
    mov edi, read_buffer
    rep stosd
    
    ; Read a line from books.txt
    mov eax, 3              ; syscall: read
    mov ebx, [file_descriptor]
    mov ecx, read_buffer
    mov edx, 256
    int 0x80

    ; Check for EOF or error
    cmp eax, 0
    jle borrow_book_not_found  

    ; Null-terminate the buffer
    mov byte [read_buffer + eax], 0
    
    ; Check if the line contains the search title
    mov edi, borrow_title
    mov esi, read_buffer
    call string_contains  
    cmp al, 1
    je borrow_book_found

    jmp borrow_search_loop

borrow_book_not_found:
    mov esi, book_not_found_msg
    call write_output
    jmp _start

borrow_book_found:
    ; Close books.txt
    mov eax, 6              ; syscall: close
    mov ebx, [file_descriptor]
    int 0x80

    ; Ask for borrow date
    mov esi, borrow_date_msg
    call write_output

    mov esi, borrow_date
    mov edx, 20
    call read_input
    mov edi, borrow_date
    call trim_newline

    ; Open borrow.txt for appending
    mov eax, 5              ; syscall: open
    mov ebx, borrowed_filename
    mov ecx, 0x402          ; O_RDWR | O_CREAT | O_APPEND
    mov edx, 0644o          ; Permissions: rw-r--r--
    int 0x80
    cmp eax, 0
    jl borrow_book_failed
    mov [borrowed_file_descriptor], eax  

    ; Write borrower name
    mov esi, borrower_name
    call write_to_file

    ; Append separator " | "
    mov esi, delimiter
    call write_to_file

    ; Write phone number
    mov esi, borrower_phone
    call write_to_file

    ; Append separator " | "
    mov esi, delimiter
    call write_to_file

    ; Write book title
    mov esi, borrow_title
    call write_to_file

    ; Append separator " | "
    mov esi, delimiter
    call write_to_file

    ; Write borrow date
    mov esi, borrow_date
    call write_to_file

    ; Write newline after the borrow record
    mov esi, newline
    call write_to_file

    ; Close borrow.txt
    mov eax, 6              ; syscall: close
    mov ebx, [borrowed_file_descriptor]
    int 0x80

    mov esi, book_borrowed_msg
    call write_output
    jmp _start

borrow_book_failed:
    mov esi, fail_msg
    call write_output
    jmp _start


; =================================================
; DISPLAY ALL BORROWS 
; =================================================


display_borrows:
    ; Open borrow.txt for reading
    mov eax, 5              ; syscall: open
    mov ebx, borrowed_filename
    mov ecx, 0               ; O_RDONLY
    int 0x80
    cmp eax, 0
    jl display_borrows_failed  ; If file open fails, show error

    mov [borrowed_file_descriptor], eax  ; Store file descriptor

    ; Print header
    mov esi, separator
    call write_output

    ; Set flag to check if file is empty
    mov byte [book_found], 0

display_borrows_loop:
    ; Clear read buffer
    xor eax, eax
    mov ecx, 64            ; Clear in 4-byte chunks (256/4 = 64)
    mov edi, read_buffer
    rep stosd
    
    ; Read a line from borrow.txt
    mov eax, 3              ; syscall: read
    mov ebx, [borrowed_file_descriptor]
    mov ecx, read_buffer
    mov edx, 256
    int 0x80

    ; Check for EOF or error
    cmp eax, 0
    je display_borrows_done  ; If EOF, finish process

    ; Set flag (indicating that at least one borrow record exists)
    mov byte [book_found], 1

    ; Print the borrow record
    mov esi, read_buffer
    call write_output

    ; Print a newline after the borrow record
    mov esi, newline
    call write_output

    ; Print separator after each borrow record
    mov esi, separator
    call write_output

    jmp display_borrows_loop

display_borrows_done:
    ; Close the borrow.txt file
    mov eax, 6              ; syscall: close
    mov ebx, [borrowed_file_descriptor]
    int 0x80

    ; Check if no borrow records were found
    cmp byte [book_found], 0
    jne display_borrows_success

    ; No records found, display a message
    mov esi, book_not_found_msg
    call write_output

display_borrows_success:
    jmp _start  ; Return to menu

display_borrows_failed:
    ; Failed to open file message
    mov esi, fail_msg
    call write_output
    jmp _start

; =================================================
; EXIT PROGRAM
; =================================================

exit_program:
    ; Display thank you message
    mov esi, thanks_msg  
    call write_output    

    ; Print a newline after the thank you message
    mov esi, newline
    call write_output

    ; Check and close `books.txt`
    cmp dword [file_descriptor], 0
    jle .skip_close_books
    mov eax, 6              ; syscall: close
    mov ebx, [file_descriptor]
    int 0x80
.skip_close_books:

    ; Check and close `borrow.txt`
    cmp dword [borrowed_file_descriptor], 0
    jle .skip_close_borrow
    mov eax, 6              ; syscall: close
    mov ebx, [borrowed_file_descriptor]
    int 0x80
.skip_close_borrow:

    ; Check and close `temp.txt`
    cmp dword [temp_file_descriptor], 0
    jle .skip_close_temp
    mov eax, 6              ; syscall: close
    mov ebx, [temp_file_descriptor]
    int 0x80
.skip_close_temp:

    ; Exit program
    mov eax, 1              ; syscall: exit
    xor ebx, ebx            ; Exit code 0
    int 0x80
