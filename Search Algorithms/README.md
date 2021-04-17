# Assignment 1. Search Algorithms

## Description
During pandemic times, you need to keep yourself and others safe. Your goal is to reach home, but you forgot the mask at the library. You might be able to buy the mask on your way to the home.

### Actor
You start from bottom left. Your goal is to reach home in as minimum number of steps as possible. Your ability to perceive covid is defined in the “variants section” below. Your algorithms will work on both variants. The actor can move one step per turn and can move horizontally, vertically and diagonally.

### Covid
Covid’s perception is only in consecutive cells (Moore neighborhood). There are 2 covid agents generated randomly on the map. You do not want to face covid as it ends the game. You are safe from covid only if you enter its perception zone after visiting the doctor or you already got the mask.

### Doctor
The doctor is generated randomly on the map but cannot be in the covid zone. You do not know the location of the doctor’s cell. You can perceive the doctor only when you are inside the doctor’s cell. Once you go inside the doctor’s cell, you are vaccinated and covid cannot harm you even if you go inside covid infected cells.

### Home
Home is randomly generated on the map except inside the covid infected cells. You know the location of the home.

### Mask
Mask is generated randomly and is not in the covid zone. You do not know the location of the mask. You can perceive mask only when you are inside the mask cell. If you get the mask, covid cannot harm you even if you go inside covid infected cells.

### Variants
The algorithms consider two scenarios:
1. In one scenario, you can perceive covid if you are standing next to the covid infected cells.
2. In the other scenario, you can perceive covid from a larger distance, which is, when you are 1 square away from the covid infected cells.

### Input
The algorithms input is a 9*9 square lattice. The map has a single actor, 2 covid agents, a doctor, mask, and home.

### Output
The output comprises of
1. Outcome: Win or Lose.
2. The number of steps algorithm took to reach home.
3. The path on the map.
4. Time taken by the algorithm to reach home.

## Program
The program has implementations of two algorithms: Backtracking and BFS.\
It runs both of them one by one.

### How to start
The program works fine in the terminal.
It can be download from this website:
https://www.swi-prolog.org/download/stable

To start the program it is enough to write the following command inside the terminal:
```
['/Path/Code.pl'].
```
Where *Path* is the absolute path to the *Code.pl* file on the computer.

Unfortunately, the online compiler doesn't suuport *assert()* and *setof* rules :\(
So, it is not recommended to use this site https://swish.swi-prolog.org/example/swish_tutorials.swinb
to test the program, since the backtracking won't work there.
However, it is OK to use online compiler to test only *BFS algorithm*.
In this case, you should remove the following lines in the beginning of *test(Input)* rule:
```Prolog
start_backtracking(Data, variant1),
start_backtracking(Data, variant2),
```

### How to test

The *Code.pl* file contains the prolog code with algorithms and all necessary rules.
In particular, there are the Backtracking algorithm and the BFS algorithm implementations.

Each of them can be called separately from the following rules:
```Prolog
start_backtracking(Data, variant1),
start_bfs(Data, variant1),
```

where the *Data* is the set of agent's coordinates.
It is represented in the following form:
```Prolog
Data = [Map, Actor, Home, Mask, Doctor, Covid1, Covid2],
Map = [N, M],
Actor = [ActorX, ActorY],
Home = [HomeX, HomeY],
Mask = [MaskX, MaskY],
Doctor = [DoctorX, DoctorY],
Covid1 = [Covid1X, Covid1Y],
Covid2 = [Covid2X, Covid2Y],
```

However, there is an easy way how to test algorithms.
The file also contains the *test()* function.
So, if you want to test any particular map, then it is better to write input in the following form:
```Prolog
test([9, 9, [0, 0], [7, 7], [3, 3], [1, 2], [5, 6], [6, 5]]).
```
which corresponds to the following input type:
```Prolog
test([N, M, [ActorX, ActorY], [HomeX, HomeY], [MaskX, MaskY], [DoctorX, DoctorY], [Covid1X, Covid1Y], [Covid2X, Covid2Y]]).
```
In our case, the input will be interpreted is the following:
```Prolog
Map = [9, 9],
Actor = [0, 0],
Home = [7, 7],
Mask = [3, 3],
Doctor = [1, 2],
Covid1 = [5, 6],
Covid2 = [6, 5],
```

The second possible way to start algorithms is the following call:
```Prolog
test([N, M]).
```
In this case, the map will be generated randomly.
For example, if we want to generate the map which has size 9x6,
then we should call *test()* rule as the following:
```Prolog
test([9, 6]).
```

### Program output

After calling *test()* rule, the program will launch **Backtracking** algorithm with two variants,
the it will launch the **BFS** algorithm with two variants.
Firstly, it will output the input data and the map which consists of special symbols:
A - Actor, H - home, M - mask, D - doctor, C - COVID.
\* - free cell, x - part of the shortest path.

When the algorithm has finished, the program outputs its result:
outcome result, found path, number of steps and the time of execution.

All in all, the output will be in the following form:
```
?- test([9,9]).
Input data:
Map size [N:M] = [9,9]
Actor = [0,0]
Home = [7,7]
Mask = [2,7]
Doctor = [4,0]
Covid1 = [3,3]
Covid2 = [7,2]

The map:
* * * * * * * * *
* * M * * * * H *
* * * * * * * * *
* * * * * * * * *
* * * * * * * * *
* * * C * * * * *
* * * * * * * C *
* * * * * * * * *
A * * * D * * * *

Start backtracking variant 1...

1) Win.
2) The number of steps: 10
3) The path: [[0,0],[1,1],[1,2],[1,3],[1,4],[2,5],[3,6],[4,7],[5,7],[6,7],[7,7]]
* * * * * * * * *
* * M * x x x H *
* * * x * * * * *
* * x * * * * * *
* x * * * * * * *
* x * C * * * * *
* x * * * * * C *
* x * * * * * * *
A * * * D * * * *

4) Time = 0.027307987213134766 seconds

Start backtracking variant 2...

1) Win.
2) The number of steps: 10
3) The path: [[0,0],[1,0],[2,0],[3,0],[4,1],[5,2],[5,3],[6,4],[7,5],[7,6],[7,7]]
* * * * * * * * *
* * M * * * * H *
* * * * * * * x *
* * * * * * * x *
* * * * * * x * *
* * * C * x * * *
* * * * * x * C *
* * * * x * * * *
A x x x D * * * *

4) Time = 2.5373449325561523 seconds

Start BFS algorithm variant 1...

1) Win.
2) The number of steps: 10
3) The path: [[0,0],[0,1],[0,2],[0,3],[1,4],[2,5],[3,6],[4,7],[5,8],[6,8],[7,7]]
* * * * * x x * *
* * M * x * * H *
* * * x * * * * *
* * x * * * * * *
* x * * * * * * *
x * * C * * * * *
x * * * * * * C *
x * * * * * * * *
A * * * D * * * *

4) Time = 1.7613768577575684 seconds

Start BFS algorithm variant 2...

1) Win.
2) The number of steps: 10
3) The path: [[0,0],[0,1],[0,2],[0,3],[1,4],[2,5],[3,6],[4,7],[5,8],[6,8],[7,7]]
* * * * * x x * *
* * M * x * * H *
* * * x * * * * *
* * x * * * * * *
* x * * * * * * *
x * * C * * * * *
x * * * * * * C *
x * * * * * * * *
A * * * D * * * *

4) Time = 0.37635111808776855 seconds

true.
```
