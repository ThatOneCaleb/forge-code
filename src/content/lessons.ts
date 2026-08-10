import type { Lesson } from "../engine/types";

/**
 * Lessons interleaved into the path. Each is anchored `before` a challenge id
 * and carries a small, pre-filled WORKING example the learner runs to see the
 * concept in action. Example JS is machine-verified by lessons.test.ts.
 *
 * Adding lessons is data-only — append here (or via /add-lesson).
 */
export const LESSONS: Lesson[] = [
  {
    id: "l-welcome",
    title: "Welcome to the Forge",
    topic: "Basics",
    concept: "How solving works",
    before: "hello-forge",
    body: `## What is code?

Code is just instructions — steps you write down so a computer knows exactly what to do. The computer follows them in order, every single time, without getting confused or bored.

Every challenge in Forge Code asks you to write one small set of instructions called a **function**. A function is like a machine: you put something in, it does some work, and hands something back out.

## Your machine is called solve

Your function is always named **solve**, and it always receives one thing called **text** — the puzzle input. Whatever you **return** is your answer. Forge Code compares it to the expected answer for you.

## The example, line by line

Read through this slowly — every word matters:

\`\`\`javascript
function solve(text) {
  return "Hi, " + text;
}
\`\`\`

- **Line 1** — "Start a function named \`solve\`. The thing it receives will be called \`text\`."
- **Line 2** — "Glue the words \`"Hi, "\` and whatever is in \`text\` together, then send the result back."
- The word \`return\` is what sends your answer out. Forget it and nothing comes back.

## Python looks almost the same

You can switch languages with the toggle above the editor. Python's version is:

\`\`\`python
def solve(text):
    return "Hi, " + text
\`\`\`

Same idea, just spelled a little differently.

Hit **Run** to watch it work. Then try changing \`"Hi, "\` to \`"Hello, "\` and run it again — you just changed code!`,
    example: {
      prompt: "Return a friendly hello to the name in the input.",
      input: "Sprocket",
      expected: "Hi, Sprocket",
      code: {
        javascript: `function solve(text) {\n  return "Hi, " + text;\n}\n`,
        python: `def solve(text):\n    return "Hi, " + text\n`,
      },
    },
  },
  {
    id: "l-conditions",
    title: "Choices & Remainders",
    topic: "Basics",
    concept: "if / else and modulo",
    before: "even-odd",
    body: `## Variables: labeled boxes

A **variable** is like a labeled box that holds a value. You give it a name, put something inside, and use that name to get the value back later.

\`\`\`javascript
const score = 42;          // a box called "score" holding the number 42
const name  = "Sprocket";  // a box called "name" holding the text "Sprocket"
\`\`\`

In Python, it's even simpler — no \`const\` needed:
\`\`\`python
score = 42
name  = "Sprocket"
\`\`\`

## Numbers in disguise

When a number arrives through \`text\`, it looks like \`"7"\` — text, not a real number. You have to unwrap it before you can do math with it:

- JavaScript: \`Number(text)\` turns \`"7"\` into \`7\`
- Python: \`int(text)\` does the same thing

## Making decisions with if / else

Programs make choices with **if / else**. Think of it as a fork in the road: "if this is true, go left; otherwise, go right."

\`\`\`javascript
if (n > 10) {
  // runs when n is bigger than 10
} else {
  // runs in every other case
}
\`\`\`

## The example, line by line

\`\`\`javascript
function solve(text) {
  const n = Number(text);              // unwrap the text into a real number
  return n > 10 ? "big" : "small";    // if n > 10, return "big"; else "small"
}
\`\`\`

The \`?\` and \`:\` on the second line are a quick shortcut for if/else. Read it as: "if \`n > 10\` is true, give me \`"big"\`, otherwise give me \`"small"\`."

Hit **Run**, then try changing \`10\` to \`5\` and see which inputs change their answer.`,
    example: {
      prompt: 'Return "big" if the number is over 10, otherwise "small".',
      input: "7",
      expected: "small",
      code: {
        javascript: `function solve(text) {\n  const n = Number(text);\n  return n > 10 ? "big" : "small";\n}\n`,
        python: `def solve(text):\n    n = int(text)\n    return "big" if n > 10 else "small"\n`,
      },
    },
  },
  {
    id: "l-loops",
    title: "Loops & Ranges",
    topic: "Loops",
    concept: "Repeating with a loop",
    before: "sum-to-n",
    body: `## What is a loop?

A **loop** runs the same instructions over and over — once for each step in a range, or once for each item in a list. Without loops, you would have to write the same line hundreds of times.

## Counting with a loop

Here is a loop that counts from 1 to 5 in JavaScript:

\`\`\`javascript
for (let i = 1; i <= 5; i++) {
  // i is 1 on the first pass, 2 on the second, ... up to 5
}
\`\`\`

Read the first line as three instructions separated by semicolons:
1. **Start:** \`let i = 1\` — set \`i\` to 1
2. **Keep going while:** \`i <= 5\` — stop when \`i\` gets bigger than 5
3. **After each pass:** \`i++\` — add 1 to \`i\`

Python uses a simpler spelling for the same idea:
\`\`\`python
for i in range(1, 6):   # range(1, 6) gives 1, 2, 3, 4, 5 (stops before 6)
    pass
\`\`\`

## Collecting results

Inside a loop, you can build up a list of results and join them into a string at the end:

\`\`\`javascript
const out = [];            // start with an empty list
out.push(1);               // add 1 → [1]
out.push(2);               // add 2 → [1, 2]
out.join(" ");             // join into "1 2"
\`\`\`

## The example, line by line

\`\`\`javascript
function solve(text) {
  const n = Number(text);          // turn the input into a number
  const out = [];                  // empty list to collect results
  for (let i = 1; i <= n; i++) {  // count from 1 to n
    out.push(i);                   // add i to the list each turn
  }
  return out.join(" ");            // join everything into "1 2 3 ..."
}
\`\`\`

Hit **Run**, then change the input from \`3\` to \`6\` and run again — watch the loop do more work.`,
    example: {
      prompt: "Return the numbers 1 to N separated by spaces.",
      input: "3",
      expected: "1 2 3",
      code: {
        javascript: `function solve(text) {\n  const n = Number(text);\n  const out = [];\n  for (let i = 1; i <= n; i++) out.push(i);\n  return out.join(" ");\n}\n`,
        python: `def solve(text):\n    n = int(text)\n    return " ".join(str(i) for i in range(1, n + 1))\n`,
      },
    },
  },
  {
    id: "l-strings",
    title: "Working with Strings",
    topic: "Strings",
    concept: "Looping over characters",
    before: "count-vowels",
    body: `## What is a string?

A **string** is text stored in a program. It lives inside quotes and can contain letters, numbers, spaces — anything you can type.

\`\`\`javascript
const word     = "hello";    // a string with 5 characters
const greeting = "Hi there"; // a string with 8 characters (space counts!)
\`\`\`

Strings are made of characters laid out in order, like beads on a necklace.

## Looping over characters

You can visit each character one at a time with a **for-of** loop:

\`\`\`javascript
for (const c of "hello") {
  // c is "h" on pass 1, "e" on pass 2, "l", "l", "o"
}
\`\`\`

## Counting a specific character

Start a counter at 0, then add 1 every time you find the character you are looking for:

\`\`\`javascript
let count = 0;
for (const c of text) {
  if (c === "a") count++;    // count++ is short for count = count + 1
}
\`\`\`

## Upper-case vs. lower-case

\`"A"\` and \`"a"\` are different characters to a computer. To treat them the same, convert the whole string to lower-case first:

- JavaScript: \`text.toLowerCase()\`
- Python: \`text.lower()\`

## The example, line by line

\`\`\`javascript
function solve(text) {
  let count = 0;
  for (const c of text.toLowerCase()) {  // loop, treating everything as lower-case
    if (c === "a") count++;              // found an "a" — add 1 to count
  }
  return count;                          // send back the total
}
\`\`\`

Hit **Run**. Then try changing \`"a"\` to \`"n"\` and run again — you are now counting a different letter.`,
    example: {
      prompt: 'Count how many times the letter "a" appears (any case).',
      input: "Banana",
      expected: "3",
      code: {
        javascript: `function solve(text) {\n  let count = 0;\n  for (const c of text.toLowerCase()) if (c === "a") count++;\n  return count;\n}\n`,
        python: `def solve(text):\n    return sum(1 for c in text.lower() if c == "a")\n`,
      },
    },
  },
  {
    id: "l-lists",
    title: "Lists of Numbers",
    topic: "Collections",
    concept: "Split & convert",
    before: "max-of-list",
    body: `## What is a list?

A **list** (called an **array** in JavaScript) is a collection of things stored in order. You can put numbers, words, or anything else inside:

\`\`\`javascript
const nums  = [3, 1, 4];     // a list of 3 numbers
const words = ["cat", "dog"]; // a list of 2 words
\`\`\`

You can grab any item by its **position** — positions start at 0, not 1:

\`\`\`javascript
nums[0]  // 3 (first item)
nums[1]  // 1 (second item)
nums[2]  // 4 (third item)
\`\`\`

## Turning a text line into a list

Puzzle inputs often give you several numbers on one line: \`"2 4 6"\`. The trick is to **split** that text into pieces:

\`\`\`javascript
"2 4 6".split(/\s+/)  // → ["2", "4", "6"]
\`\`\`

Python:
\`\`\`python
"2 4 6".split()  # → ["2", "4", "6"]
\`\`\`

But those pieces are still text — not real numbers yet! To do math, convert each piece:

\`\`\`javascript
"2 4 6".split(/\s+/).map(Number)  // → [2, 4, 6]  (now real numbers)
\`\`\`

\`.map(Number)\` applies \`Number(...)\` to every item in one step.

Python:
\`\`\`python
[int(x) for x in "2 4 6".split()]  # → [2, 4, 6]
\`\`\`

## The example, line by line

\`\`\`javascript
function solve(text) {
  const nums = text.split(/\s+/).map(Number); // split into pieces, convert to numbers
  let total = 0;
  for (const n of nums) total += n;           // add each number to total
  return total;                               // send back the sum
}
\`\`\`

Hit **Run**, then try changing the input to \`"1 2 3 4 5"\` and see the new total.`,
    example: {
      prompt: "Add up a line of space-separated numbers.",
      input: "2 4 6",
      expected: "12",
      code: {
        javascript: `function solve(text) {\n  const nums = text.split(/\\s+/).map(Number);\n  let total = 0;\n  for (const n of nums) total += n;\n  return total;\n}\n`,
        python: `def solve(text):\n    return sum(int(x) for x in text.split())\n`,
      },
    },
  },
  {
    id: "l-sets",
    title: "Sets Remove Duplicates",
    topic: "Collections",
    concept: "The set",
    before: "unique-count",
    body: `## What is a set?

A **set** is like a list, but with one special rule: **no duplicates allowed**. If you add the same value twice, the second one is silently ignored.

\`\`\`javascript
const s = new Set();
s.add("apple");   // set: {"apple"}
s.add("banana");  // set: {"apple", "banana"}
s.add("apple");   // ignored! still {"apple", "banana"}
s.size;           // 2
\`\`\`

Python:
\`\`\`python
s = set()
s.add("apple")
s.add("banana")
s.add("apple")   # ignored
len(s)           # 2
\`\`\`

## The duplicate-detection trick

Here is a clever use of this rule: if you drop a list of items into a set and the set comes out **smaller**, some items must have been repeated.

\`\`\`javascript
const items = ["a", "b", "a", "c"];   // 4 items
const unique = new Set(items);        // set: {"a", "b", "c"} — 3 items
unique.size < items.length            // true → there were duplicates
\`\`\`

That one comparison — set size vs. list length — is the whole check.

## The example, line by line

\`\`\`javascript
function solve(text) {
  const parts = text.split(/\s+/);              // split input into words
  return new Set(parts).size < parts.length     // set smaller than list?
    ? "yes"   // yes → duplicates exist
    : "no";   // no → all unique
}
\`\`\`

Hit **Run**, then try changing the input to \`"1 2 3 4"\` (all unique) and see how the answer changes.`,
    example: {
      prompt: 'Return "yes" if the list has any duplicates, otherwise "no".',
      input: "1 2 2 3",
      expected: "yes",
      code: {
        javascript: `function solve(text) {\n  const parts = text.split(/\\s+/);\n  return new Set(parts).size < parts.length ? "yes" : "no";\n}\n`,
        python: `def solve(text):\n    parts = text.split()\n    return "yes" if len(set(parts)) < len(parts) else "no"\n`,
      },
    },
  },
  {
    id: "l-smart-loops",
    title: "Spotting a Repeat",
    topic: "Technique",
    concept: "Detect the first repeat with a set",
    before: "is-prime",
    body: `A **set** is a fast memory of what you've already added to it, you can ask "is this already in here?" and get an instant answer.

Add each item to the set as you go, checking first whether it's there.`,
    example: {
      prompt: 'Return the first character that appears twice in the text (or "none").',
      input: "programmer",
      expected: "r",
      code: {
        javascript: `function solve(text) {\n  const seen = new Set();\n  for (const c of text) {\n    if (seen.has(c)) return c;\n    seen.add(c);\n  }\n  return "none";\n}\n`,
        python: `def solve(text):\n    seen = set()\n    for c in text:\n        if c in seen:\n            return c\n        seen.add(c)\n    return "none"\n`,
      },
    },
  },
  {
    id: "l-maps",
    title: "All Different?",
    topic: "Technique",
    concept: "Uniqueness with a set",
    before: "most-common",
    body: `A **set** throws away duplicates. So if you drop a group of items into one and it comes out **smaller** than the group, something was repeated; if the size is unchanged, they were all different.

\`new Set(items).size === items.length\` is the whole check.`,
    example: {
      prompt: "Return yes if every character in the text is different, otherwise no.",
      input: "abcd",
      expected: "yes",
      code: {
        javascript: `function solve(text) {\n  const s = text.trim();\n  return new Set(s).size === s.length ? "yes" : "no";\n}\n`,
        python: `def solve(text):\n    s = text.strip()\n    return "yes" if len(set(s)) == len(s) else "no"\n`,
      },
    },
  },
  {
    id: "l-recursion",
    title: "Tracking Where You Are",
    topic: "Technique",
    concept: "A path is a stack of names",
    before: "power-recursion",
    body: `A **stack** lets you keep a "where am I" as you move into and out of nested places: **push** a name when you go in, **pop** it when you come out. Read top to bottom, the stack is your current location.`,
    example: {
      prompt: 'Each line is "in <name>" or "out". Return the final path, names joined by "/".',
      input: "in a\nin b\nout\nin c",
      expected: "a/c",
      code: {
        javascript: `function solve(text) {\n  const stack = [];\n  for (const line of text.trim().split("\\n")) {\n    if (line === "out") stack.pop();\n    else stack.push(line.slice(3));\n  }\n  return stack.join("/");\n}\n`,
        python: `def solve(text):\n    stack = []\n    for line in text.strip().split("\\n"):\n        if line == "out":\n            stack.pop()\n        else:\n            stack.append(line[3:])\n    return "/".join(stack)\n`,
      },
    },
  },
  {
    id: "l-parsing",
    title: "Act II. Parsing the Deep",
    topic: "Parsing",
    concept: "Multi-line input",
    before: "rucksack-priorities",
    body: `The trials of the deep hand you **multi-line** input. Your first job is always to parse it into a shape you can work with.

- Split on newlines (\`\\n\`) to get a list of lines.
- Then split or slice each line as needed.

Getting the parsing right is half of every hard puzzle. The example just counts the lines.`,
    example: {
      prompt: "Return how many lines the input has.",
      input: "alpha\nbeta\ngamma",
      expected: "3",
      code: {
        javascript: `function solve(text) {\n  return text.split(/\\n/).length;\n}\n`,
        python: `def solve(text):\n    return len(text.split("\\n"))\n`,
      },
    },
  },
  {
    id: "l-stack",
    title: "The Stack",
    topic: "Algorithms",
    concept: "Last in, first out",
    before: "balanced-brackets",
    body: `A **stack** is a list where you only add to and remove from the top, last in, first out.

You **push** to add and **pop** to take the most recent item back off. Stacks are the natural tool for matching things that nest, like brackets.

The example reverses text by pushing every character, then popping them all.`,
    example: {
      prompt: "Reverse the text using a stack (push each char, then pop).",
      input: "forge",
      expected: "egrof",
      code: {
        javascript: `function solve(text) {\n  const stack = [];\n  for (const c of text) stack.push(c);\n  let out = "";\n  while (stack.length) out += stack.pop();\n  return out;\n}\n`,
        python: `def solve(text):\n    stack = list(text)\n    out = ""\n    while stack:\n        out += stack.pop()\n    return out\n`,
      },
    },
  },
  {
    id: "l-grids",
    title: "Grids & Flood Fill",
    topic: "Grids",
    concept: "2D iteration",
    before: "count-regions",
    body: `A grid is just a list of rows, each a string of cells. Reach a cell with \`grid[row][col]\`.

To explore connected shapes, you visit a cell, then its up/down/left/right **neighbours**, marking each one **seen** so you never revisit. That spreading search is called **flood fill**.

The example warms up with the simplest grid task: counting cells.`,
    example: {
      prompt: "Count the '#' cells in the grid.",
      input: "#.\n.#",
      expected: "2",
      code: {
        javascript: `function solve(text) {\n  let count = 0;\n  for (const row of text.split(/\\n/)) for (const c of row) if (c === "#") count++;\n  return count;\n}\n`,
        python: `def solve(text):\n    return sum(row.count("#") for row in text.split("\\n"))\n`,
      },
    },
  },
  {
    id: "l-cycles",
    title: "Cycle Detection",
    topic: "Algorithms",
    concept: "Remembering what you've seen",
    before: "reactor-cycles",
    body: `To find the first time something **repeats**, keep a **set** of everything you've seen. Before adding a new value, check whether it's already in the set, if so, that's your first repeat.

This one idea powers loop detection, "have I been here before?" in mazes, and the reactor's resonance.

The example finds the first repeated number in a line.`,
    example: {
      prompt: "Return the first number that appears twice, scanning left to right.",
      input: "3 1 4 1 5",
      expected: "1",
      code: {
        javascript: `function solve(text) {\n  const seen = new Set();\n  for (const x of text.split(/\\s+/)) {\n    if (seen.has(x)) return x;\n    seen.add(x);\n  }\n  return "none";\n}\n`,
        python: `def solve(text):\n    seen = set()\n    for x in text.split():\n        if x in seen:\n            return x\n        seen.add(x)\n    return "none"\n`,
      },
    },
  },
  {
    id: "l-parse-numbers",
    title: "Numbers Hiding in Text",
    topic: "Basics",
    concept: "Split & convert to numbers",
    before: "sum-two",
    body: `Input usually arrives as **text**. To do math, split it into pieces and convert each piece to a number.\n\n- JavaScript: \`text.split(/\\s+/).map(Number)\`\n- Python: \`[int(x) for x in text.split()]\`\n\nThe example multiplies the two numbers.`,
    example: {
      prompt: "Multiply the two numbers in the input.",
      input: "4 5",
      expected: "20",
      code: {
        javascript: `function solve(text) {\n  const [a, b] = text.split(/\\s+/).map(Number);\n  return a * b;\n}\n`,
        python: `def solve(text):\n    a, b = map(int, text.split())\n    return a * b\n`,
      },
    },
  },
  {
    id: "l-abs",
    title: "Absolute Value",
    topic: "Basics",
    concept: "Distance is never negative",
    before: "abs-diff",
    body: `The **absolute value** of a number is its size, ignoring the sign, \`abs(-7)\` is \`7\`. It's how you measure the distance between two numbers no matter which is bigger.\n\n- JavaScript: \`Math.abs(x)\`\n- Python: \`abs(x)\``,
    example: {
      prompt: "Return the absolute value of the number.",
      input: "-7",
      expected: "7",
      code: {
        javascript: `function solve(text) {\n  return Math.abs(Number(text));\n}\n`,
        python: `def solve(text):\n    return abs(int(text))\n`,
      },
    },
  },
  {
    id: "l-case-trim",
    title: "Upper, Lower & Trim",
    topic: "Strings",
    concept: "Reshaping text",
    before: "shout",
    body: `Text has handy transforms:\n- **trim** removes the spaces at the ends (\`.trim()\` / \`.strip()\`)\n- **upper / lower** change the case (\`.toUpperCase()\` / \`.upper()\`)\n\nThe example trims the spaces and lowercases the text.`,
    example: {
      prompt: "Trim the spaces and return the text in lowercase.",
      input: "  HELLO  ",
      expected: "hello",
      code: {
        javascript: `function solve(text) {\n  return text.trim().toLowerCase();\n}\n`,
        python: `def solve(text):\n    return text.strip().lower()\n`,
      },
    },
  },
  {
    id: "l-slices",
    title: "Slices & Reversing",
    topic: "Strings",
    concept: "Taking pieces of a string",
    before: "reverse",
    body: `You can take a **slice** of a string by position.\n- First 3 characters. JS \`text.slice(0, 3)\`, Python \`text[:3]\`\n- Reversed. JS \`[...text].reverse().join("")\`, Python \`text[::-1]\`\n\nThe example returns the first three characters.`,
    example: {
      prompt: "Return the first 3 characters.",
      input: "forge",
      expected: "for",
      code: {
        javascript: `function solve(text) {\n  return text.slice(0, 3);\n}\n`,
        python: `def solve(text):\n    return text[:3]\n`,
      },
    },
  },
  {
    id: "l-loop-build",
    title: "Building Output in a Loop",
    topic: "Loops",
    concept: "Repeat and collect",
    before: "count-down",
    body: `A loop can build a result step by step, add to a string or collect into a list, one turn at a time.\n\nThe example repeats a star N times.`,
    example: {
      prompt: "Return a row of N stars.",
      input: "5",
      expected: "*****",
      code: {
        javascript: `function solve(text) {\n  const n = Number(text);\n  let out = "";\n  for (let i = 0; i < n; i++) out += "*";\n  return out;\n}\n`,
        python: `def solve(text):\n    return "*" * int(text)\n`,
      },
    },
  },
  {
    id: "l-accumulate",
    title: "Running Totals",
    topic: "Loops",
    concept: "Accumulators",
    before: "factorial",
    body: `An **accumulator** is a variable you update every loop. Start it at 0 for sums, at 1 for products.\n\nThe example sums the squares: 1² + 2² + … + N².`,
    example: {
      prompt: "Sum the squares from 1 to N.",
      input: "3",
      expected: "14",
      code: {
        javascript: `function solve(text) {\n  const n = Number(text);\n  let total = 0;\n  for (let i = 1; i <= n; i++) total += i * i;\n  return total;\n}\n`,
        python: `def solve(text):\n    n = int(text)\n    return sum(i * i for i in range(1, n + 1))\n`,
      },
    },
  },
  {
    id: "l-divisible",
    title: "Divisibility & OR",
    topic: "Loops",
    concept: "Combining conditions",
    before: "fizzbuzz-count",
    body: `\`n % k === 0\` means *k divides n evenly*. Combine tests with **or** (\`||\` / \`or\`) to match several cases at once.\n\nThe example counts the multiples of 3.`,
    example: {
      prompt: "Count the multiples of 3 from 1 to N.",
      input: "10",
      expected: "3",
      code: {
        javascript: `function solve(text) {\n  const n = Number(text);\n  let c = 0;\n  for (let i = 1; i <= n; i++) if (i % 3 === 0) c++;\n  return c;\n}\n`,
        python: `def solve(text):\n    n = int(text)\n    return sum(1 for i in range(1, n + 1) if i % 3 == 0)\n`,
      },
    },
  },
  {
    id: "l-split-words",
    title: "Splitting into Words",
    topic: "Strings",
    concept: "split()",
    before: "count-words",
    body: `Splitting text on spaces gives a list of words. Grab one by index, or count them with length.\n\nThe example returns the first word.`,
    example: {
      prompt: "Return the first word.",
      input: "the quick brown",
      expected: "the",
      code: {
        javascript: `function solve(text) {\n  return text.trim().split(/\\s+/)[0];\n}\n`,
        python: `def solve(text):\n    return text.split()[0]\n`,
      },
    },
  },
  {
    id: "l-modulo-loop",
    title: "Inside a Range?",
    topic: "Technique",
    concept: "Range membership",
    before: "gcd",
    body: `A number \`x\` lies inside the range \`a..b\` (inclusive) exactly when \`a <= x && x <= b\`, two comparisons joined with **and**.

Comparing endpoints like this is the building block for reasoning about ranges.`,
    example: {
      prompt: 'The input is "a b x". Return yes if x is inside the range a..b (inclusive), else no.',
      input: "3 7 5",
      expected: "yes",
      code: {
        javascript: `function solve(text) {\n  const [a, b, x] = text.split(/\\s+/).map(Number);\n  return a <= x && x <= b ? "yes" : "no";\n}\n`,
        python: `def solve(text):\n    a, b, x = map(int, text.split())\n    return "yes" if a <= x <= b else "no"\n`,
      },
    },
  },
  {
    id: "l-sequence",
    title: "Stepping Toward a Target",
    topic: "Technique",
    concept: "Nudge a value one step toward another",
    before: "fibonacci",
    body: `To nudge one value toward another, look at the **sign** of \`target − current\`: if the target is larger, step +1; smaller, −1; equal, don't move.

In two dimensions you apply it to each axis on its own.`,
    example: {
      prompt: 'The input is "from to". Return -1, 0, or 1, the direction you would step from "from" toward "to".',
      input: "3 7",
      expected: "1",
      code: {
        javascript: `function solve(text) {\n  const [a, b] = text.split(/\\s+/).map(Number);\n  const d = b - a;\n  return d > 0 ? 1 : d < 0 ? -1 : 0;\n}\n`,
        python: `def solve(text):\n    a, b = map(int, text.split())\n    d = b - a\n    return 1 if d > 0 else -1 if d < 0 else 0\n`,
      },
    },
  },
  {
    id: "l-sorting",
    title: "Reading Fixed Columns",
    topic: "Technique",
    concept: "Index characters by position",
    before: "sort-desc",
    body: `Some inputs are laid out in **fixed columns**, the character you want sits at the same position on every line. Instead of splitting into words, index straight to it with \`line[pos]\`.

Positions are counted from 0, so \`line[1]\` is the second character.`,
    example: {
      prompt: 'Each line looks like "[N]". Read the character at position 1 from each line, top to bottom, into one string.',
      input: "[N]\n[Z]\n[M]",
      expected: "NZM",
      code: {
        javascript: `function solve(text) {\n  return text.split("\\n").map((line) => line[1]).join("");\n}\n`,
        python: `def solve(text):\n    return "".join(line[1] for line in text.split("\\n"))\n`,
      },
    },
  },
  {
    id: "l-digits",
    title: "Manhattan Distance",
    topic: "Technique",
    concept: "Grid distance without diagonals",
    before: "binary-to-decimal",
    body: `On a grid where you can only step up, down, left, or right, the distance between two points is the **Manhattan distance**: \`|x1 − x2| + |y1 − y2|\`, the number of steps you'd actually take.`,
    example: {
      prompt: 'The input is "x1 y1 x2 y2". Return the Manhattan distance between the two points.',
      input: "2 3 5 7",
      expected: "7",
      code: {
        javascript: `function solve(text) {\n  const [x1, y1, x2, y2] = text.split(/\\s+/).map(Number);\n  return Math.abs(x1 - x2) + Math.abs(y1 - y2);\n}\n`,
        python: `def solve(text):\n    x1, y1, x2, y2 = map(int, text.split())\n    return abs(x1 - x2) + abs(y1 - y2)\n`,
      },
    },
  },
  {
    id: "l-lines",
    title: "Records So Far",
    topic: "Technique",
    concept: "Running maximum",
    before: "grid-count",
    body: `As you scan a sequence, keep the **biggest value seen so far**. A value is a new record when it's strictly greater than that running maximum, update the maximum whenever that happens.`,
    example: {
      prompt: "Scanning left to right, count how many numbers are strictly bigger than everything before them.",
      input: "2 5 3 6 1",
      expected: "3",
      code: {
        javascript: `function solve(text) {\n  let best = -Infinity, count = 0;\n  for (const n of text.split(/\\s+/).map(Number)) {\n    if (n > best) { count++; best = n; }\n  }\n  return count;\n}\n`,
        python: `def solve(text):\n    best = float("-inf")\n    count = 0\n    for n in map(int, text.split()):\n        if n > best:\n            count += 1\n            best = n\n    return count\n`,
      },
    },
  },
  {
    id: "l-blank-groups",
    title: "Blank-Line Groups",
    topic: "Parsing",
    concept: "Splitting on blank lines",
    before: "calorie-groups",
    body: `Data is often split into groups separated by a blank line. Split the whole text on a **double newline** to get the groups, then process each one.\n\nThe example counts the groups.`,
    example: {
      prompt: "How many groups are there (separated by a blank line)?",
      input: "1\n2\n\n3",
      expected: "2",
      code: {
        javascript: `function solve(text) {\n  return text.split(/\\n\\s*\\n/).length;\n}\n`,
        python: `def solve(text):\n    return len(text.split("\\n\\n"))\n`,
      },
    },
  },
  {
    id: "l-nested",
    title: "Nested Loops",
    topic: "Algorithms",
    concept: "Loops inside loops",
    before: "pair-sums",
    body: `To compare every **pair** of items, put one loop inside another, with the inner starting just after the outer (\`j = i + 1\`) so each pair is counted once.\n\nThe example counts how many unique pairs exist among N items.`,
    example: {
      prompt: "Given N, count how many unique pairs (i < j) there are.",
      input: "4",
      expected: "6",
      code: {
        javascript: `function solve(text) {\n  const n = Number(text);\n  let c = 0;\n  for (let i = 0; i < n; i++) for (let j = i + 1; j < n; j++) c++;\n  return c;\n}\n`,
        python: `def solve(text):\n    n = int(text)\n    c = 0\n    for i in range(n):\n        for j in range(i + 1, n):\n            c += 1\n    return c\n`,
      },
    },
  },
  {
    id: "l-dijkstra",
    title: "Cheapest-First Search",
    topic: "Search",
    concept: "Dijkstra: expand the cheapest option first",
    before: "hazard-descent",
    body: `When each move has a **cost** and you want the cheapest way from a start to a goal, plain breadth-first search isn't enough, the fewest moves isn't always the cheapest.

**Dijkstra's idea:** keep a best-known cost to reach each place (start = 0, everything else = infinity). Repeatedly take the *unvisited place with the smallest known cost*, mark it done, and relax its neighbours: if going through it is cheaper than their current best, update them.

The example works on a tiny network of numbered nodes, each line is \`from to cost\`, and finds the cheapest total from node 0 to the last node. A grid is just the same idea where every step's cost is the cell you enter.`,
    example: {
      prompt: "First line is the node count N. Each other line is 'from to cost'. Return the cheapest total cost from node 0 to node N-1.",
      input: "4\n0 1 4\n0 2 1\n2 1 1\n1 3 1\n2 3 5",
      expected: "3",
      code: {
        javascript: `function solve(text) {\n  const lines = text.trim().split("\\n");\n  const n = Number(lines[0]);\n  const adj = Array.from({ length: n }, () => []);\n  for (const line of lines.slice(1)) {\n    const [a, b, w] = line.split(" ").map(Number);\n    adj[a].push([b, w]);\n  }\n  const dist = new Array(n).fill(Infinity);\n  dist[0] = 0;\n  const seen = new Array(n).fill(false);\n  for (let it = 0; it < n; it++) {\n    let u = -1;\n    for (let i = 0; i < n; i++) if (!seen[i] && (u === -1 || dist[i] < dist[u])) u = i;\n    if (u === -1) break;\n    seen[u] = true;\n    for (const [v, w] of adj[u]) if (dist[u] + w < dist[v]) dist[v] = dist[u] + w;\n  }\n  return dist[n - 1];\n}\n`,
        python: `def solve(text):\n    lines = text.strip().split("\\n")\n    n = int(lines[0])\n    adj = [[] for _ in range(n)]\n    for line in lines[1:]:\n        a, b, w = map(int, line.split())\n        adj[a].append((b, w))\n    dist = [float('inf')] * n\n    dist[0] = 0\n    seen = [False] * n\n    for _ in range(n):\n        u = -1\n        for i in range(n):\n            if not seen[i] and (u == -1 or dist[i] < dist[u]):\n                u = i\n        if u == -1:\n            break\n        seen[u] = True\n        for v, w in adj[u]:\n            if dist[u] + w < dist[v]:\n                dist[v] = dist[u] + w\n    return dist[n - 1]\n`,
      },
    },
  },
  {
    id: "l-cycle-align",
    title: "Locking Cycles Together",
    topic: "Math",
    concept: "Combine repeating cycles by stepping in growing strides",
    before: "beacon-alignment",
    body: `Two things repeat on their own rhythms, one every few ticks, another every few more. You want the first moment they both line up. Checking every single tick works but crawls once the periods get large.

**The trick:** solve one cycle at a time. Start at time \`t = 0\` with a stride of \`1\`. Satisfy the first cycle, then *grow the stride* to that cycle's period. Now every future step keeps the first cycle aligned, so you only search for the next one. Multiply the stride by each period as you lock it in.

This works cleanly when the periods share no common factor. The example takes a few cycles written as \`period offset\` (meaning \`(t + offset)\` must be divisible by \`period\`) and finds the earliest \`t\` that satisfies them all.`,
    example: {
      prompt: "First line is the cycle count N. Each other line is 'period offset', meaning (t + offset) must be divisible by period. Return the earliest t (t can be 0) satisfying all of them.",
      input: "2\n3 0\n4 1",
      expected: "3",
      code: {
        javascript: `function solve(text) {\n  const lines = text.trim().split("\\n");\n  const n = Number(lines[0]);\n  const cycles = lines.slice(1, n + 1).map((l) => l.split(" ").map(Number));\n  let t = 0, step = 1;\n  for (const [period, offset] of cycles) {\n    while ((t + offset) % period !== 0) t += step;\n    step *= period;\n  }\n  return t;\n}\n`,
        python: `def solve(text):\n    lines = text.strip().split("\\n")\n    n = int(lines[0])\n    cycles = [tuple(map(int, l.split())) for l in lines[1:n + 1]]\n    t, step = 0, 1\n    for period, offset in cycles:\n        while (t + offset) % period != 0:\n            t += step\n        step *= period\n    return t\n`,
      },
    },
  },

  // ── Bridge lessons: fill the gap from Academy basics to Gauntlet-ready ──

  {
    id: "l-dicts",
    title: "Dictionaries",
    topic: "Data Structures",
    concept: "Key-value stores for counting, grouping, and lookup",
    before: "dict-build",
    body: `## What is a Dictionary?

A dictionary stores data as **key-value pairs**. Think of a real dictionary: you look up a word (the *key*) and instantly get its definition (the *value*). In Python it is called a \`dict\`; in JavaScript it is an \`Object\`.

Dictionaries are one of the most powerful tools in programming. Every Gauntlet puzzle that involves counting, grouping, or fast lookup will use one.

## Creating a Dictionary

Start empty and fill it as you go, or pre-load with values:

\`\`\`python
scores = {}              # empty
scores["Alice"] = 95    # add an entry
scores["Bob"]   = 87    # add another

# Or create with values already inside
scores = {"Alice": 95, "Bob": 87}
\`\`\`

## Reading Values

Use square brackets with the key:

\`\`\`python
print(scores["Alice"])  # 95
\`\`\`

If the key might not exist, use \`.get()\` with a fallback default to avoid a crash:

\`\`\`python
print(scores.get("Eve", 0))  # 0 (safe, no KeyError)
\`\`\`

## The Counting Pattern

The single most common dictionary pattern in Forge puzzles: count occurrences.

\`\`\`python
counts = {}
for word in text.split():
    counts[word] = counts.get(word, 0) + 1
\`\`\`

Read \`counts.get(word, 0) + 1\` as: "get the current count for this word (or 0 if it has not appeared yet), then add 1." After the loop, every word maps to how many times it appeared.

## Looping Over a Dictionary

You can loop over keys, values, or both at once:

\`\`\`python
for name in scores:                    # just keys
    print(name)

for score in scores.values():          # just values
    print(score)

for name, score in scores.items():     # both together
    print(f"{name} scored {score}")
\`\`\`

The \`.items()\` loop is the most useful one — you will use it constantly.

## Sorting Keys for Predictable Output

For alphabetical output, wrap the key loop in \`sorted()\`:

\`\`\`python
for name in sorted(scores):
    print(name, scores[name])
\`\`\`

## Common Mistake: Missing Keys

Never read a key that might not be there yet:

\`\`\`python
print(scores["Eve"])          # CRASHES with KeyError if Eve is missing
print(scores.get("Eve", 0))   # safe: returns 0 instead
\`\`\`

## Why Dictionaries Beat Lists for Lookup

Looking up a value in a list means scanning every item from the start — slow for large data. Looking up in a dictionary is instant, no matter how big it grows. That matters when your puzzle has thousands of lines.

Master the "build a dict while scanning, then query it" pattern and a large chunk of the Gauntlet opens up immediately.`,
    example: {
      prompt: "Count how many times each letter appears in the word, output alphabetically as 'letter:count' pairs.",
      input: "hello",
      expected: "e:1 h:1 l:2 o:1",
      code: {
        javascript: `function solve(text) {\n  const counts = {};\n  for (const ch of text) counts[ch] = (counts[ch] || 0) + 1;\n  return Object.keys(counts).sort().map(k => k + ':' + counts[k]).join(' ');\n}\n`,
        python: `def solve(text):\n    counts = {}\n    for ch in text:\n        counts[ch] = counts.get(ch, 0) + 1\n    return ' '.join(f'{k}:{v}' for k, v in sorted(counts.items()))\n`,
      },
    },
  },

  {
    id: "l-sort-keys",
    title: "Sorting with a Key",
    topic: "Sorting",
    concept: "sorted() with key= to control what gets compared",
    before: "sort-scores",
    body: `## Sorting: More Than Alphabetical

Python can sort lists automatically. But often you need to sort by a *specific rule* — like "sort these name-score pairs by score, not by name." The \`key=\` argument lets you tell Python exactly what to compare.

## Basic sorted()

\`sorted(sequence)\` returns a **new** sorted list (the original is unchanged):

\`\`\`python
words = ["banana", "apple", "cherry"]
print(sorted(words))         # ["apple", "banana", "cherry"]
print(sorted(words, reverse=True))  # ["cherry", "banana", "apple"]
\`\`\`

## Sorting with a Key Function

The \`key=\` argument takes a function. Python calls that function on each item and sorts by what it returns:

\`\`\`python
words = ["banana", "fig", "apple", "blueberry"]
by_length = sorted(words, key=len)
# ["fig", "apple", "banana", "blueberry"]
\`\`\`

Here \`key=len\` tells Python: "sort by how long each word is." The function \`len\` is called on every word, and the results are used for ordering.

## Lambda: A Tiny One-Line Function

When you need a custom key, use \`lambda\`:

\`\`\`python
pairs = [["Alice", 72], ["Bob", 95], ["Carol", 88]]

# Sort by the second element (the score)
sorted_pairs = sorted(pairs, key=lambda p: p[1])
# [["Alice", 72], ["Carol", 88], ["Bob", 95]]  (ascending)

# Add reverse=True for highest first
sorted_pairs = sorted(pairs, key=lambda p: p[1], reverse=True)
# [["Bob", 95], ["Carol", 88], ["Alice", 72]]
\`\`\`

Read \`lambda p: p[1]\` as: "a tiny function that takes \`p\` and returns \`p[1]\`." Python uses that return value to decide the order.

## Negative Key Trick (Python only)

A quick shortcut for descending sort without \`reverse=True\` — negate the number:

\`\`\`python
sorted(pairs, key=lambda p: -int(p[1]))
\`\`\`

Bigger numbers become more-negative, so they sort first. Useful when you are nesting keys.

## Sorting in JavaScript

JavaScript's \`.sort()\` sorts *in place* and takes a **comparator** function:

\`\`\`javascript
const pairs = [["Alice", 72], ["Bob", 95], ["Carol", 88]];
pairs.sort((a, b) => Number(b[1]) - Number(a[1]));  // descending by score
// [["Bob", 95], ["Carol", 88], ["Alice", 72]]
\`\`\`

If the comparator returns a negative number, \`a\` comes first. Positive means \`b\` comes first.

## Extract Just What You Need After Sorting

Often you sort pairs and then want only one part:

\`\`\`python
names_in_order = [p[0] for p in sorted(pairs, key=lambda p: -int(p[1]))]
\`\`\`

This is a very common two-step pattern: sort pairs by some criterion, then pull out the part you actually need to return.`,
    example: {
      prompt: "Sort words from shortest to longest.",
      input: "banana fig apple blueberry",
      expected: "fig apple banana blueberry",
      code: {
        javascript: `function solve(text) {\n  return text.trim().split(' ').sort((a, b) => a.length - b.length).join(' ');\n}\n`,
        python: `def solve(text):\n    return ' '.join(sorted(text.split(), key=len))\n`,
      },
    },
  },

  {
    id: "l-list-comp",
    title: "List Comprehensions",
    topic: "Functional Style",
    concept: "Build filtered or transformed lists in a single expression",
    before: "filter-list",
    body: `## Building Lists the Long Way

When you want to build a new list from an existing one, the classic approach is to create an empty list and loop:

\`\`\`python
numbers = [1, 2, 3, 4, 5, 6, 7, 8]
evens = []
for n in numbers:
    if n % 2 == 0:
        evens.append(n)
# evens = [2, 4, 6, 8]
\`\`\`

This works, but Python has a more compact way to write exactly this.

## List Comprehensions

A **list comprehension** does the same thing in one line:

\`\`\`python
evens = [n for n in numbers if n % 2 == 0]
\`\`\`

Read it left to right: "put \`n\` in the new list, for each \`n\` in \`numbers\`, but only if \`n % 2 == 0\`."

The three pieces:
- **expression** — what goes in the result list (\`n\`)
- **for clause** — where the values come from (\`for n in numbers\`)
- **if clause** — optional filter (\`if n % 2 == 0\`)

## Transforming While Filtering

You can transform each item at the same time as filtering:

\`\`\`python
# Double only the even numbers
doubled_evens = [n * 2 for n in numbers if n % 2 == 0]
# [4, 8, 12, 16]
\`\`\`

The expression at the front (\`n * 2\`) can be anything — a calculation, a function call, a string operation.

## Working with Strings

List comprehensions are great for text too:

\`\`\`python
words = ["cat", "elephant", "dog", "rhinoceros", "fox"]
long_words = [w for w in words if len(w) > 4]
# ["elephant", "rhinoceros"]

upper_words = [w.upper() for w in words]
# ["CAT", "ELEPHANT", "DOG", "RHINOCEROS", "FOX"]
\`\`\`

## Generator Expressions

If you only need to loop over the result once (like passing it to \`sum()\` or \`' '.join()\`), drop the outer brackets for a *generator expression* — it is slightly more efficient:

\`\`\`python
total = sum(n for n in numbers if n > 5)
result = ' '.join(w for w in words if len(w) > 3)
\`\`\`

Generator expressions look the same as list comprehensions but with \`()\` instead of \`[]\`.

## In JavaScript: .filter() and .map()

JavaScript uses chained methods instead of comprehension syntax:

\`\`\`javascript
const nums = [1, 2, 3, 4, 5, 6];

// filter: keep only items where the function returns true
const evens = nums.filter(n => n % 2 === 0);         // [2, 4, 6]

// map: transform every item
const doubled = nums.map(n => n * 2);                // [2, 4, 6, 8, 10, 12]

// chain them: filter then transform
const result = nums.filter(n => n > 2).map(n => n * 10);  // [30, 40, 50, 60]
\`\`\`

## When to Use a Comprehension

Use a comprehension when you want a new list that is a filtered or transformed version of another list. If you just want a single value (a sum, a count, a max), use \`sum()\`, \`len()\`, or \`max()\` directly with a generator expression.`,
    example: {
      prompt: "Keep only the words longer than 4 characters.",
      input: "cat elephant dog rhinoceros fox",
      expected: "elephant rhinoceros",
      code: {
        javascript: `function solve(text) {\n  return text.trim().split(' ').filter(w => w.length > 4).join(' ');\n}\n`,
        python: `def solve(text):\n    return ' '.join(w for w in text.split() if len(w) > 4)\n`,
      },
    },
  },

  {
    id: "l-fstrings",
    title: "String Formatting",
    topic: "Strings",
    concept: "f-strings and template literals: embed values inside strings",
    before: "format-report",
    body: `## The Problem with String Building

When you need to include a variable inside a string, the old-fashioned way was to chop strings together with \`+\`:

\`\`\`python
name = "Alice"
score = 95
message = "Hello, " + name + "! You scored " + str(score) + " points."
\`\`\`

This is messy, easy to forget a space, and you have to convert numbers to strings manually. There is a much better way.

## Python f-strings

Prefix a string with \`f\` and put any expression inside \`{}\`:

\`\`\`python
name = "Alice"
score = 95
message = f"Hello, {name}! You scored {score} points."
# "Hello, Alice! You scored 95 points."
\`\`\`

Python evaluates whatever is inside the curly braces and inserts the result. You can put variables, calculations, function calls — anything that produces a value:

\`\`\`python
x = 7
print(f"The square of {x} is {x ** 2}.")  # "The square of 7 is 49."
print(f"{'hello'.upper()} world")          # "HELLO world"
\`\`\`

## Formatting Numbers

You can control how numbers look inside the braces:

\`\`\`python
pi = 3.14159
print(f"Pi to 2 decimal places: {pi:.2f}")   # "Pi to 2 decimal places: 3.14"
print(f"Padded to 5 digits: {42:05d}")        # "Padded to 5 digits: 00042"
\`\`\`

The \`:.2f\` means "float, 2 decimal places." You will not need this for most Forge puzzles, but it is useful when the output asks for rounded numbers.

## JavaScript Template Literals

JavaScript uses backtick strings (\`) with \`\${}\` for the same idea:

\`\`\`javascript
const name = "Alice";
const score = 95;
const message = \`Hello, \${name}! You scored \${score} points.\`;
\`\`\`

Same rules: anything inside \`\${}\` gets evaluated and inserted.

## Building Multiple Lines

When you need to format each line of output differently, loop over the data and build a list of formatted strings, then join with \`\\n\`:

\`\`\`python
entries = [("Alice", 95), ("Bob", 87), ("Carol", 92)]
lines = [f"{name}: {score} points" for name, score in entries]
result = '\\n'.join(lines)
\`\`\`

This pattern — format each item, collect into a list, join — appears constantly in Forge puzzles that ask for multi-line output.

## Common Mistake: Forgetting the f

\`\`\`python
# Missing f — the braces are treated as literal text:
message = "Hello, {name}!"   # outputs literally "Hello, {name}!"

# Correct:
message = f"Hello, {name}!"  # outputs "Hello, Alice!"
\`\`\`

Python will not warn you; it will just output the braces literally. If your output looks wrong, check for a missing \`f\`.`,
    example: {
      prompt: "Given 'name age', return 'name is age years old.'",
      input: "Alice 17",
      expected: "Alice is 17 years old.",
      code: {
        javascript: `function solve(text) {\n  const [name, age] = text.trim().split(' ');\n  return \`\${name} is \${age} years old.\`;\n}\n`,
        python: `def solve(text):\n    name, age = text.split()\n    return f'{name} is {age} years old.'\n`,
      },
    },
  },

  {
    id: "l-nested-loops",
    title: "Nested Loops and 2D Data",
    topic: "Grids",
    concept: "Loops inside loops: processing rows and columns of a grid",
    before: "grid-sum",
    body: `## When One Loop Is Not Enough

A single loop works great for a flat list. But when your data has rows *and* columns — a grid, a table, a matrix — you need a loop inside a loop.

## A Simple Nested Loop

\`\`\`python
for row in range(3):
    for col in range(3):
        print(f"({row}, {col})", end="  ")
    print()  # newline after each row
\`\`\`

Output:
\`\`\`
(0, 0)  (0, 1)  (0, 2)
(1, 0)  (1, 1)  (1, 2)
(2, 0)  (2, 1)  (2, 2)
\`\`\`

The inner loop runs completely for every single step of the outer loop. If the outer loop has 3 steps and the inner loop has 3 steps, the inner body runs 3 × 3 = 9 times total.

## Parsing a Grid from Text

Forge puzzles often give you a grid as multi-line text: each line is a row, and values in each row are separated by spaces. Here is the standard way to parse it:

\`\`\`python
text = "1 2 3\\n4 5 6\\n7 8 9"
rows = text.strip().split('\\n')
grid = [list(map(int, row.split())) for row in rows]
# grid[0] = [1, 2, 3]
# grid[1] = [4, 5, 6]
# grid[2] = [7, 8, 9]
\`\`\`

Now \`grid[row][col]\` gives you any cell.

## Summing All Cells

\`\`\`python
total = 0
for row in grid:
    for value in row:
        total += value
print(total)  # 45
\`\`\`

Or with a nested comprehension (flattening the grid):

\`\`\`python
total = sum(value for row in grid for value in row)
\`\`\`

## Checking Neighbors

Many Forge grid puzzles require checking the cells around a given cell. A common pattern uses offsets:

\`\`\`python
DIRECTIONS = [(-1, 0), (1, 0), (0, -1), (0, 1)]  # up, down, left, right

for dr, dc in DIRECTIONS:
    nr, nc = row + dr, col + dc
    if 0 <= nr < len(grid) and 0 <= nc < len(grid[0]):
        # (nr, nc) is a valid neighbor
        print(grid[nr][nc])
\`\`\`

The bounds check (\`0 <= nr < rows\`) is crucial — skipping it causes index-out-of-range crashes at the edges.

## In JavaScript

JavaScript handles the same idea with arrays of arrays:

\`\`\`javascript
const grid = text.trim().split('\\n').map(row => row.split(' ').map(Number));
let total = 0;
for (const row of grid) {
    for (const val of row) {
        total += val;
    }
}
\`\`\`

## Key Insight: Time Complexity

If each dimension has N items, a nested loop runs N² times. For grids of 100×100 (10,000 cells) that is totally fine. For grids of 10,000×10,000 (100 million iterations) you would need a smarter approach — but most Forge grids are small enough that nested loops work perfectly.`,
    example: {
      prompt: "Find the largest number in the grid.",
      input: "3 1 4\n1 5 9\n2 6 5",
      expected: "9",
      code: {
        javascript: `function solve(text) {\n  return Math.max(...text.trim().split('\\n').flatMap(r => r.split(' ').map(Number)));\n}\n`,
        python: `def solve(text):\n    return max(int(n) for row in text.strip().split('\\n') for n in row.split())\n`,
      },
    },
  },

  {
    id: "l-multiline",
    title: "Parsing Multi-Line Text",
    topic: "Text Processing",
    concept: "Split text into lines, then split each line into fields",
    before: "ledger-max",
    body: `## The Shape of Puzzle Input

Almost every Gauntlet puzzle gives you a multi-line string. The structure varies: sometimes each line is a single value, sometimes each line has several fields separated by spaces or colons, sometimes there are blank-line-separated sections. Knowing how to break these down quickly is essential.

## Step 1: Split into Lines

\`\`\`python
lines = text.strip().split('\\n')
\`\`\`

\`text.strip()\` removes any leading/trailing whitespace (including a trailing newline that puzzles often have). \`.split('\\n')\` breaks on newlines, giving you a list of line strings.

## Step 2: Split Each Line into Fields

If each line has space-separated fields:

\`\`\`python
for line in lines:
    parts = line.split()   # split on any whitespace
    name  = parts[0]
    score = int(parts[1])
\`\`\`

If the separator is something else (a colon, comma, dash):

\`\`\`python
a, b = line.split(':')   # "10:20" → ["10", "20"]
lo, hi = line.split('-') # "5-12"  → ["5", "12"]
\`\`\`

## Unpacking in One Step

Python lets you assign multiple variables from a split in one line:

\`\`\`python
name, score = line.split()
# same as: parts = line.split(); name = parts[0]; score = parts[1]
\`\`\`

This only works if the line has exactly the right number of fields. If the count might vary, use indexing instead.

## Building a Result While Parsing

A common pattern: scan every line and accumulate something:

\`\`\`python
totals = {}
for line in lines:
    name, amount = line.split()
    totals[name] = totals.get(name, 0) + int(amount)
\`\`\`

This builds a dictionary of running totals as you read, which you can then query or sort at the end.

## Handling Blank-Line Sections

Some puzzles separate groups with a blank line. Split on double newlines:

\`\`\`python
groups = text.strip().split('\\n\\n')
for group in groups:
    lines_in_group = group.split('\\n')
    # process each group's lines
\`\`\`

## Stripping Whitespace Per Line

If lines might have leading or trailing spaces:

\`\`\`python
lines = [line.strip() for line in text.split('\\n') if line.strip()]
\`\`\`

The \`if line.strip()\` at the end filters out blank lines automatically.

## In JavaScript

\`\`\`javascript
const lines = text.trim().split('\\n');
for (const line of lines) {
    const [name, score] = line.split(' ');
    // use name and Number(score)
}
\`\`\`

## A Note on Line Endings

On Windows, lines sometimes end with \`\\r\\n\` instead of \`\\n\`. \`text.strip()\` removes trailing \`\\r\` characters, so always strip before splitting if you want safe cross-platform behavior.`,
    example: {
      prompt: "Given lines of 'name score', return the sum of all scores.",
      input: "Alice 10\nBob 20\nCarol 15",
      expected: "45",
      code: {
        javascript: `function solve(text) {\n  return text.trim().split('\\n').reduce((sum, l) => sum + Number(l.split(' ')[1]), 0);\n}\n`,
        python: `def solve(text):\n    return sum(int(line.split()[1]) for line in text.strip().split('\\n'))\n`,
      },
    },
  },

  {
    id: "l-recursion-intro",
    title: "Recursion",
    topic: "Algorithms",
    concept: "A function that calls itself to solve a smaller version of the problem",
    before: "digit-root",
    body: `## What Is Recursion?

Recursion is when a function **calls itself**. This sounds circular, but it works because each call works on a *smaller* version of the problem, until you reach a version so small you can answer it directly.

Every recursive function has two parts:

1. **Base case** — the simplest input where you return an answer directly (no more calls).
2. **Recursive case** — everything else; call the same function with a *smaller* input, then use that result.

## A Concrete Example: Countdown

\`\`\`python
def countdown(n):
    if n == 0:           # base case: stop here
        print("Done!")
        return
    print(n)
    countdown(n - 1)    # recursive case: call with n-1

countdown(3)
# prints: 3, 2, 1, Done!
\`\`\`

Each call to \`countdown\` passes \`n - 1\`, making the problem one step smaller. When \`n\` reaches 0, the base case fires and the chain stops.

## Returning a Value: Factorial

\`\`\`python
def factorial(n):
    if n == 0 or n == 1:    # base case
        return 1
    return n * factorial(n - 1)   # recursive case

print(factorial(5))  # 120  (5 × 4 × 3 × 2 × 1)
\`\`\`

\`factorial(5)\` calls \`factorial(4)\`, which calls \`factorial(3)\`, and so on until \`factorial(1)\` returns 1. Then the chain unwinds: 1, 1×2=2, 2×3=6, 6×4=24, 24×5=120.

## Digit Sum — A Recursive Approach

Adding the digits of a number until you reach a single digit is a natural fit for recursion:

\`\`\`python
def digit_sum(n):
    if n < 10:              # base case: already a single digit
        return n
    total = sum(int(d) for d in str(n))
    return digit_sum(total)  # recursive: call with the digit sum

print(digit_sum(493))   # 493 → 16 → 7
\`\`\`

## The Call Stack

Each recursive call is remembered until it returns. Think of it as a stack of paused work:

\`\`\`
digit_sum(493) waits for →
  digit_sum(16) waits for →
    digit_sum(7) returns 7
  digit_sum(16) returns 7
digit_sum(493) returns 7
\`\`\`

## When to Use Recursion

Recursion shines when a problem has self-similar structure: trees, nested brackets, grids you explore outward from a point, or any sequence where "the answer for N depends on the answer for N-1." For flat loops, a regular \`for\` or \`while\` loop is usually simpler. For problems with depth or branching, recursion often leads to the cleanest code.

## Common Mistake: Missing the Base Case

Without a base case, the function calls itself forever until Python raises a \`RecursionError\`:

\`\`\`python
def bad(n):
    return bad(n - 1)   # never stops!
\`\`\`

Always write the base case *first* before writing the recursive case.`,
    example: {
      prompt: "Compute n! (factorial) recursively. Input is a single number.",
      input: "5",
      expected: "120",
      code: {
        javascript: `function solve(text) {\n  function fact(n) { return n <= 1 ? 1 : n * fact(n - 1); }\n  return fact(Number(text));\n}\n`,
        python: `def solve(text):\n    def fact(n):\n        if n <= 1:\n            return 1\n        return n * fact(n - 1)\n    return fact(int(text))\n`,
      },
    },
  },

  {
    id: "l-stacks",
    title: "Stacks",
    topic: "Data Structures",
    concept: "Last-in, first-out storage with append and pop",
    before: "stack-top",
    body: `## What Is a Stack?

A **stack** is a collection where the last item you add is the first one you remove — like a stack of plates. This rule is called **LIFO**: Last In, First Out.

Stacks appear in bracket matching, undo systems, expression evaluation, depth-first search, and a surprising number of Forge puzzles.

## Stacks in Python and JavaScript

You do not need a special data structure — a regular list works perfectly:

- **Push** (add to top): \`.append(value)\` in Python, \`.push(value)\` in JavaScript
- **Pop** (remove from top): \`.pop()\` in both languages

\`\`\`python
stack = []
stack.append(5)   # stack: [5]
stack.append(3)   # stack: [5, 3]
stack.append(7)   # stack: [5, 3, 7]
stack.pop()       # removes 7, stack: [5, 3]
top = stack[-1]   # peek at the top without removing: 3
\`\`\`

The *end* of the list is the "top" of the stack. That is why \`.pop()\` (which removes the last element) gives you the most-recently-added item.

## Simulating Operations

When a puzzle describes a sequence of push/pop operations, process them line by line:

\`\`\`python
stack = []
for line in text.strip().split('\\n'):
    if line.startswith('push'):
        value = int(line.split()[1])
        stack.append(value)
    elif line == 'pop':
        stack.pop()
\`\`\`

## Bracket Matching

The classic stack puzzle: do the brackets balance?

\`\`\`python
def is_balanced(s):
    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    for ch in s:
        if ch in '([{':
            stack.append(ch)
        elif ch in ')]}':
            if not stack or stack[-1] != pairs[ch]:
                return False
            stack.pop()
    return len(stack) == 0

print(is_balanced("(a [b] c)"))   # True
print(is_balanced("(a [b) c]"))   # False
\`\`\`

The rule: every opening bracket goes onto the stack. Every closing bracket must match the most-recently-opened one. If the stack is empty at the end, all brackets were matched.

## Checking Before Popping

Always check that the stack is not empty before calling \`.pop()\`, or you will get an error:

\`\`\`python
if stack:
    stack.pop()   # safe
\`\`\`

## Peek Without Removing

To look at the top without removing it:

\`\`\`python
top = stack[-1]   # Python: last element
\`\`\`

\`\`\`javascript
const top = stack[stack.length - 1];  // JavaScript
\`\`\`

## Why Stacks Work

A stack lets you *remember where you came from*. When you go deeper into a problem (opening a bracket, entering a directory, starting a sub-expression), you push the context. When you finish and return, you pop it. The thing waiting at the top of the stack is exactly what you need next.`,
    example: {
      prompt: "Simulate push/pop ops and return the final top value.",
      input: "push 10\npush 4\npush 7\npop",
      expected: "4",
      code: {
        javascript: `function solve(text) {\n  const stack = [];\n  for (const line of text.trim().split('\\n')) {\n    if (line.startsWith('push')) stack.push(Number(line.split(' ')[1]));\n    else if (line === 'pop') stack.pop();\n  }\n  return stack[stack.length - 1];\n}\n`,
        python: `def solve(text):\n    stack = []\n    for line in text.strip().split('\\n'):\n        if line.startswith('push'):\n            stack.append(int(line.split()[1]))\n        elif line == 'pop':\n            stack.pop()\n    return stack[-1]\n`,
      },
    },
  },

  {
    id: "l-zip",
    title: "zip() and enumerate()",
    topic: "Iteration",
    concept: "Walk two sequences in lockstep; track position while looping",
    before: "zip-teams",
    body: `## The Problem: Two Lists, One Loop

Sometimes you have two lists that go together — names and scores, keys and values, before and after states — and you need to process them side by side. You could use an index:

\`\`\`python
names  = ["Alice", "Bob", "Carol"]
scores = [90, 85, 92]

for i in range(len(names)):
    print(f"{names[i]}: {scores[i]}")
\`\`\`

This works, but Python has a much cleaner way.

## zip(): Pair Two Sequences

\`zip(a, b)\` produces pairs from two sequences, matching by position:

\`\`\`python
for name, score in zip(names, scores):
    print(f"{name}: {score}")
# Alice: 90
# Bob: 85
# Carol: 92
\`\`\`

It stops when the shorter sequence runs out, so it is safe even if the lists have different lengths.

You can zip more than two sequences at once:

\`\`\`python
for name, score, rank in zip(names, scores, [1, 2, 3]):
    print(f"#{rank} {name}: {score}")
\`\`\`

## Building Pairs

Often you want to combine two lists into a list of pairs:

\`\`\`python
pairs = list(zip(names, scores))
# [("Alice", 90), ("Bob", 85), ("Carol", 92)]
\`\`\`

Or a dictionary (if one list contains keys and the other contains values):

\`\`\`python
lookup = dict(zip(names, scores))
# {"Alice": 90, "Bob": 85, "Carol": 92}
\`\`\`

This dict-from-zip pattern is very handy when you have separate key and value lists.

## enumerate(): Loop With an Index

\`enumerate(sequence)\` gives you both the index and the value at each step:

\`\`\`python
words = ["zero", "one", "two", "three"]
for i, word in enumerate(words):
    print(f"{i}: {word}")
# 0: zero
# 1: one
# 2: two
# 3: three
\`\`\`

You can start counting from a different number:

\`\`\`python
for i, word in enumerate(words, start=1):
    print(f"{i}: {word}")   # counts 1, 2, 3, 4
\`\`\`

## In JavaScript

JavaScript uses array indexing or \`.entries()\` for the same ideas:

\`\`\`javascript
const names  = ["Alice", "Bob", "Carol"];
const scores = [90, 85, 92];

// Pair by index (zip equivalent)
const pairs = names.map((n, i) => [n, scores[i]]);

// Enumerate with index
names.forEach((n, i) => console.log(i + ': ' + n));

// entries() on an array
for (const [i, n] of names.entries()) {
    console.log(i, n);
}
\`\`\`

## Real Usage in Forge Puzzles

When a puzzle gives you data in two separate lines or columns, zip is the natural tool. Split each line into a list, zip the two lists, and you have your pairs ready to process — no index arithmetic needed.`,
    example: {
      prompt: "Given two lines (names then scores), return 'name=score' pairs joined by commas.",
      input: "Alice Bob Carol\n90 85 92",
      expected: "Alice=90 Bob=85 Carol=92",
      code: {
        javascript: `function solve(text) {\n  const [nl, sl] = text.trim().split('\\n');\n  return nl.split(' ').map((n, i) => n + '=' + sl.split(' ')[i]).join(' ');\n}\n`,
        python: `def solve(text):\n    lines = text.strip().split('\\n')\n    names, scores = lines[0].split(), lines[1].split()\n    return ' '.join(f'{n}={s}' for n, s in zip(names, scores))\n`,
      },
    },
  },

  {
    id: "l-running",
    title: "Tracking State While Looping",
    topic: "Iteration",
    concept: "Carry a variable through a loop to track running totals, maximums, or streaks",
    before: "running-max",
    body: `## Loops That Remember

The simplest loops just visit items. But many problems need a loop that *remembers something* from previous iterations — a running total, the highest value seen so far, whether the last item was odd, how many items in a row satisfied a condition.

The key is a variable you update *inside* the loop that carries its value from one iteration to the next.

## Running Total

\`\`\`python
numbers = [3, 7, 2, 9, 1]
total = 0
for n in numbers:
    total += n       # add current value to total
print(total)  # 22
\`\`\`

\`total\` starts at 0. Each iteration adds the current number. After the loop, it holds the sum. This is the **accumulator pattern** — you have already used it in earlier challenges.

## Running Maximum

Instead of summing, track the largest value seen:

\`\`\`python
numbers = [3, 1, 4, 1, 5, 9, 2, 6]
current_max = numbers[0]     # start with the first item
for n in numbers:
    if n > current_max:
        current_max = n
print(current_max)  # 9
\`\`\`

Starting at \`numbers[0]\` (instead of 0 or negative infinity) works correctly when all numbers could be negative.

## Recording the Running State

Some puzzles ask for the running value at *each step*, not just the final answer:

\`\`\`python
numbers = [3, 1, 4, 1, 5, 9, 2, 6]
result = []
cur_max = numbers[0]
for n in numbers:
    if n > cur_max:
        cur_max = n
    result.append(cur_max)    # record the current max at this step

print(' '.join(map(str, result)))
# 3 3 4 4 5 9 9 9
\`\`\`

## Streak Counter

Count the longest run of consecutive matching items:

\`\`\`python
values = [1, 1, 0, 1, 1, 1, 0, 1]
current_streak = 0
best_streak = 0
for v in values:
    if v == 1:
        current_streak += 1
        if current_streak > best_streak:
            best_streak = current_streak
    else:
        current_streak = 0   # reset on a break
print(best_streak)  # 3
\`\`\`

Two running variables: \`current_streak\` resets on failure; \`best_streak\` only ever increases.

## Flag Variables

Sometimes the "state" is just True/False:

\`\`\`python
seen_negative = False
for n in numbers:
    if n < 0:
        seen_negative = True
        break   # no need to look further
\`\`\`

## In JavaScript

The same patterns work in JavaScript with \`let\`:

\`\`\`javascript
const nums = [3, 1, 4, 1, 5, 9, 2, 6];
let max = nums[0];
const result = nums.map(n => { if (n > max) max = n; return max; });
\`\`\`

## The Principle

Every problem that involves "what happened so far" needs a running variable. Define it before the loop, update it inside the loop, and use it (either inside the loop or after) to produce your answer. This pattern — alongside counting with dictionaries — will carry you through a huge range of Forge puzzles.`,
    example: {
      prompt: "Return the running total at each step (cumulative sum).",
      input: "1 2 3 4 5",
      expected: "1 3 6 10 15",
      code: {
        javascript: `function solve(text) {\n  let total = 0;\n  return text.trim().split(/\\s+/).map(n => (total += Number(n))).join(' ');\n}\n`,
        python: `def solve(text):\n    total = 0\n    result = []\n    for n in text.split():\n        total += int(n)\n        result.append(total)\n    return ' '.join(map(str, result))\n`,
      },
    },
  },
];

export const LESSONS_BY_ID: Record<string, Lesson> = Object.fromEntries(
  LESSONS.map((l) => [l.id, l]),
);

export function getLesson(id: string): Lesson | undefined {
  return LESSONS_BY_ID[id];
}
