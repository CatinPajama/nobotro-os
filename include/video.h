#ifndef _VIDEO_H
#define _VIDEO_H

void clear_screen();
int get_cursor_pos();
void printtext(char*,char,char);
void printchar(char,char,char);
void scroll();
void rm_char_in_pos(int);
void next_line(void);
#endif  
