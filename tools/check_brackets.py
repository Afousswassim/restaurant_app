import sys
from collections import deque

path = sys.argv[1]
text = open(path, encoding='utf-8').read()
stack = deque()
pairs = {'(':')','[':']','{':'}'}
line=1
col=0
for i,ch in enumerate(text):
    if ch=='\n':
        line+=1
        col=0
        continue
    col+=1
    if ch in pairs:
        stack.append((ch,line,col))
    elif ch in pairs.values():
        if not stack:
            print(f"Unmatched closing {ch} at {line}:{col}")
            sys.exit(1)
        last, lline, lcol = stack.pop()
        if pairs[last]!=ch:
            print(f"Mismatched {last} at {lline}:{lcol} with {ch} at {line}:{col}")
            sys.exit(1)
if stack:
    last, lline, lcol = stack.pop()
    print(f"Unclosed {last} at {lline}:{lcol}")
    sys.exit(1)
print('All brackets balanced')
