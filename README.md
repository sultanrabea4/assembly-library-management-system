# Library Management System in x86 Assembly (NASM)

A menu-driven **library management system written entirely in x86 Assembly (NASM)** for Linux. It uses **only Linux system calls**: no C library and no high-level runtime.

The project builds the low-level skills behind **malware analysis and reverse engineering**: registers, the stack, memory buffers, control flow and raw file I/O.

---

## Features
1. **Add a book**: title and author, with a check for duplicates
2. **Search for a book** by title
3. **Display all books**
4. **Borrow a book**: records the borrower's name, phone number, book title and date
5. **Display all borrow records**
6. **Exit**

Data is stored in plain-text files (`books.txt`, `borrow.txt`) using a `|` separator.

## Technical Highlights
- Direct Linux syscalls via `int 0x80`: `sys_read`, `sys_write`, `sys_open`, `sys_close`, `sys_exit`
- Manual buffer management in the `.bss` section
- String comparison and parsing implemented by hand
- Input validation and error messages for failed file operations

## Build & Run (Linux)
```bash
sudo apt install nasm
nasm -f elf32 library.asm -o library.o
ld -m elf_i386 library.o -o library
./library
```

## Example
```
Library Management System
---------------------------------
1- Add a Book
2- Search for a Book
3- Display All Books
4- Borrow a Book
5- Display All Borrows
6- Exit
---------------------------------
Enter your choice: 3
-----------------------
Title          | Author
-----------------------
The Great Gatsby|F. Scott Fitzgerald
1984|George Orwell
...
```

## Files
| File | Purpose |
|---|---|
| `library.asm` | Full source code |
| `books.txt` | Sample book catalogue |
| `borrow.txt` | Sample borrow records (fictional data) |

## Author
**Sultan Mohammed Rabea** · [LinkedIn](https://www.linkedin.com/in/sultan-rabea/) · [GitHub](https://github.com/sultanrabea4)
