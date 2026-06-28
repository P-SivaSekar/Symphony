import sys

def check_brackets(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    stack = []
    line_number = 1
    for i, char in enumerate(content):
        if char == '\n':
            line_number += 1
        elif char in '([{':
            stack.append((char, line_number))
        elif char in ')]}':
            if not stack:
                print(f"Error: Unexpected '{char}' at line {line_number}")
                return
            top_char, top_line = stack.pop()
            matches = {'(': ')', '[': ']', '{': '}'}
            if matches[top_char] != char:
                print(f"Error: Mismatched brackets at line {line_number}. Expected '{matches[top_char]}' but got '{char}'. Unclosed bracket from line {top_line}")
                return
    
    if stack:
        print(f"Error: Unclosed brackets remaining: {stack}")
    else:
        print("All brackets match perfectly!")

if __name__ == '__main__':
    check_brackets(sys.argv[1])
