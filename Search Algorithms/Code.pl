%% Test function with input which supports following formats:
%% 1) [N, M, [ActorX, ActorY], [HomeX, HomeY], [MaskX, MaskY], [DoctorX, DoctorY], [Covid1X, Covid1Y], [Covid2X, Covid2Y]]
%% 2) [N, M] - the home, mask, doctor and covids will be generated randomly.
test(Input) :-
	%% Parse input data or generate it randomly
	input(Input, Data),
	valid_map(Data),
	write("Input data:"), nl,
	print_data(Data),
	write("The map:"), nl,
	once(print_map(Data, [])),

	%% Start backtracking, variant 1 measuring the time execution
	write("Start backtracking variant 1..."), nl, nl,
	start_backtracking(Data, variant1),

	%% Start backtracking, variant 2 measuring the time execution
	write("Start backtracking variant 2..."), nl, nl,
	start_backtracking(Data, variant2),
	
	%% Start BFS algorithm, variant 1 measuring the time execution
	write("Start BFS algorithm variant 1..."), nl, nl,
	start_bfs(Data, variant1),

	%% Start BFS algorithm, variant 2 measuring the time execution
	write("Start BFS algorithm variant 2..."), nl, nl,
	start_bfs(Data, variant2),
	!.

%% Alternative test function in case of not valid input.
test(Input) :-
	input(Input, Data),
	not(valid_map(Data)),
	write("Input data:"), nl,
	print_data(Data),
	write("The input is not valid"), nl,
	!.

%% ------ BACKTRACKING rules ------
start_backtracking(Data, Variant) :-	
	get_time(StartTime),
	backtracking(Data, _Path, Variant),
	get_time(EndTime),
	Time is EndTime - StartTime,
	write("4) Time = "), write(Time), write(" seconds"),nl, nl.

%% Backtracking algorithm.
backtracking(Data, PathReverse, Variant) :-
	%% In case the path is exist
	(
		Data = [Map, _Actor, _Home, _Mask, _Doctor, _Covid1, _Covid2],
		Map = [N, M],

		Max_Length is 4 * max(N, M),

		retractall(minimal_path(_)),
		assert(minimal_path(Max_Length)),

		%% Collect all possible solutions
		setof((Steps, Path), find_path(Data, _Visited, Steps, Path, Variant), Solutions),
		%% Get the shortest path
		nth0(0, Solutions, ShortestPath, _),

		ShortestPath = (S, P),
		reverse(P, PathReverse),

		%% Print output result
		write("1) Win."), nl,
		write("2) The number of steps: "), write(S), nl,
		write("3) The path: "), write(PathReverse), nl,
		once(print_map(Data, PathReverse)), !
	);
	%% In case the path does not exist
	(
		write("1) Lose."), nl,
		PathReverse = []
	).

%% Initial start rule which sets up some initial conditions
%% and then starts the recursive search
find_path(Data, Visited, Steps, Path, Variant) :-
	Data = [_Map, Actor, _Home, _Mask, _Doctor, _Covid1, _Covid2],
	Visited = [Actor],
	Actor = [ActorX, ActorY],
	
	home_reached(ActorX, ActorY, 0, Data, Visited, Path, Variant),

	length(Path, Length),
	Steps is Length - 1,
	update_solution(Steps).

%% When the home is actually reached
home_reached(X, Y, _Protection, Data, Visited, Path, _Variant) :-
	Data = [_Map, _Actor, Home, _Mask, _Doctor, _Covid1, _Covid2],
	Home = [HomeX, HomeY],
	on_same_cell(X, Y, HomeX, HomeY),
	Path = Visited.

%% When the home is not reached, run this rule again with an additional move
home_reached(X, Y, Protection, Data, Visited, Path, Variant) :-
	%% cut long paths
	is_short_path(Visited),
	%% get new move to go
    move(X, Y, Next_X, Next_Y, Data, Variant),
    %% check whether this move is valid
    valid_move(Next_X, Next_Y, Protection, Data, Visited),
    %% check if the actor picked up the mask or met the doctor and, therefore, got the COVID protection
    protection_reached(Next_X, Next_Y, Protection, Data, NewProtection),
    %% go recursively again to this rule with additional move
    home_reached(Next_X, Next_Y, NewProtection, Data, [[Next_X, Next_Y] | Visited], Path, Variant).

%% check whether this move is valid
valid_move(X, Y, Protection, Data, Visited) :-
	%% check if the actor hasn't visited the cell before
	not(member([X, Y], Visited)),
	%% check if the cell is inside the map
	inside_map(X, Y, Data),
	%% check if the current path is still shorter than the known minimal path
	is_short_path(X, Y, Data, Visited),
	%% check is it possible to enter the cell which might be inside the COVID zone
    not_covid_affected(X, Y, Data, Protection).

%% check is it possible to enter the cell which might be inside the COVID zone
not_covid_affected(X, Y, Data, Protection) :-
	%% true if the actor has a protection
	(
		Protection == 1
	);
	%% true if the actor is not inside the COVID zone
	(
		Protection == 0,
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, Covid1, Covid2],
		Covid1 = [Covid1X, Covid1Y],
		Covid2 = [Covid2X, Covid2Y],
		not_in_covid_area(X, Y, Covid1X, Covid1Y),
		not_in_covid_area(X, Y, Covid2X, Covid2Y)
	).

%% Change the Protection variable if the actor picked up the mask or met the doctor
protection_reached(Next_X, Next_Y, Protection, Data, NewProtection) :-
  	(
	  	inside_mask_doctor(Next_X, Next_Y, Data),
	  	NewProtection is 1
    );
    (
    	not(inside_mask_doctor(Next_X, Next_Y, Data)),
    	NewProtection is Protection
    ).

%% Check if the object coordinates w.r.t. the map size
inside_map(X, Y, Data) :-
	Data = [Map, _Actor, _Home, _Mask, _Doctor, _Covid1, _Covid2],
	Map = [N, M],
    X < N,
    X >= 0,
    Y < M,
    Y >= 0.

%% Check if the actor picked up the mask or met the doctor
inside_mask_doctor(X, Y, Data) :-
	(	
		Data = [_Map, _Actor, _Home, Mask, _Doctor, _Covid1, _Covid2],
		Mask = [MaskX, MaskY],
		X == MaskX,
		Y == MaskY
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, Doctor, _Covid1, _Covid2],
		Doctor = [DoctorX, DoctorY],
		X == DoctorX,
		Y == DoctorY
	).

%% Check if the object is not in the COVID zone
not_in_covid_area(X, Y, CovidX, CovidY) :-
	distance_chebyshev(X, Y, CovidX, CovidY, Dist_cheb),
	Dist_cheb > 1.

%% Rewrite the minimal_path(Steps) fact with new found minimal length
update_solution(Steps) :-
	minimal_path(Min_Steps),
	Steps < Min_Steps,
	retractall(minimal_path(_)),
	assert(minimal_path(Steps)).

%% Calculate the minimal distance between two objects
distance_chebyshev(X1, Y1, X2, Y2, Dist_cheb) :-
	Dist_cheb is max(abs(X1 - X2), abs(Y1 - Y2)).

%% true if coordinates are the same
on_same_cell(X1, Y1, X2, Y2) :-
	X1 == X2,
	Y1 == Y2.

%% Check if the current path is still shorter than the known minimal path
%% Compare the path traveled and the known minimal path 
is_short_path(Visited) :-
	length(Visited, Length),
	Steps is Length - 1,
	minimal_path(Min_Steps),
	Steps < Min_Steps.

%% Check if the current path is still shorter than the known minimal path
%% Compare the known minimal path with the path traveled + the rest distance to reach the home
is_short_path(X, Y, Data, Visited) :-
	Data = [_Map, _Actor, Home, _Mask, _Doctor, _Covid1, _Covid2],
	Home = [HomeX, HomeY],
	distance_chebyshev(X, Y, HomeX, HomeY, Dist_cheb),
	length(Visited, Length),
	Steps is Length - 1 + Dist_cheb,
	minimal_path(Min_Steps),
	Steps < Min_Steps.

%% returns possible next move to reach the home
%% works with prioritization: firstly tries optimal moves which will require less steps to reach the home
%% for the prioritization it takes into account only the home coordinates
move(X, Y, Next_X, Next_Y, Data, variant1) :-
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, _Covid1, _Covid2],
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX == 0,
		DiffY < 0,
		(
			move_up(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, _Covid1, _Covid2],
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX < 0,
		DiffY < 0,
		(
			move_up_right(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, _Covid1, _Covid2],
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX < 0,
		DiffY == 0,
		(
			move_right(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, _Covid1, _Covid2],
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX < 0,
		DiffY > 0,
		(
			move_down_right(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, _Covid1, _Covid2],
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX == 0,
		DiffY > 0,
		(
			move_down(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, _Covid1, _Covid2],
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX > 0,
		DiffY > 0,
		(
			move_down_left(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, _Covid1, _Covid2],
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX > 0,
		DiffY == 0,
		(
			move_left(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, _Covid1, _Covid2],
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX > 0,
		DiffY < 0,
		(
			move_up_left(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y)
		)
	).


%% returns possible next move to reach the home
%% works with prioritization: firstly tries optimal moves which will require less steps to reach the home
%% for the prioritization it takes into account the home coordinates and the COVID zone perception
move(X, Y, Next_X, Next_Y, Data, variant2) :-
	%% Go to home if there is not COVID nearby
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, Covid1, Covid2],
		Covid1 = [Covid1X, Covid1Y],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid1 > 3,
		Dist_cheb_Covid2 > 3,
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX == 0,
		DiffY < 0,
		(
			move_up(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, Covid1, Covid2],
		Covid1 = [Covid1X, Covid1Y],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid1 > 3,
		Dist_cheb_Covid2 > 3,
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX < 0,
		DiffY < 0,
		(
			move_up_right(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, Covid1, Covid2],
		Covid1 = [Covid1X, Covid1Y],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid1 > 3,
		Dist_cheb_Covid2 > 3,
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX < 0,
		DiffY == 0,
		(
			move_right(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, Covid1, Covid2],
		Covid1 = [Covid1X, Covid1Y],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid1 > 3,
		Dist_cheb_Covid2 > 3,
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX < 0,
		DiffY > 0,
		(
			move_down_right(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, Covid1, Covid2],
		Covid1 = [Covid1X, Covid1Y],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid1 > 3,
		Dist_cheb_Covid2 > 3,
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX == 0,
		DiffY > 0,
		(
			move_down(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, Covid1, Covid2],
		Covid1 = [Covid1X, Covid1Y],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid1 > 3,
		Dist_cheb_Covid2 > 3,
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX > 0,
		DiffY > 0,
		(
			move_down_left(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, Covid1, Covid2],
		Covid1 = [Covid1X, Covid1Y],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid1 > 3,
		Dist_cheb_Covid2 > 3,
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX > 0,
		DiffY == 0,
		(
			move_left(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, Covid1, Covid2],
		Covid1 = [Covid1X, Covid1Y],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid1 > 3,
		Dist_cheb_Covid2 > 3,
		Home = [HomeX, HomeY],
		DiffX is X - HomeX,
		DiffY is Y - HomeY,
		DiffX > 0,
		DiffY < 0,
		(
			move_up_left(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y)
		)
	);

	%% Go opposite to COVID 1
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, Covid1, _Covid2],
		Covid1 = [Covid1X, Covid1Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		Dist_cheb_Covid1 =< 3,
		DiffX is X - Covid1X,
		DiffY is Y - Covid1Y,
		DiffX == 0,
		DiffY < 0,
		(
			move_down(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y)			
		)
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, Covid1, _Covid2],
		Covid1 = [Covid1X, Covid1Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		Dist_cheb_Covid1 =< 3,
		DiffX is X - Covid1X,
		DiffY is Y - Covid1Y,
		DiffX < 0,
		DiffY < 0,
		(
			move_down_left(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y)			
		)
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, Covid1, _Covid2],
		Covid1 = [Covid1X, Covid1Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		Dist_cheb_Covid1 =< 3,
		DiffX is X - Covid1X,
		DiffY is Y - Covid1Y,
		DiffX < 0,
		DiffY == 0,
		(
			move_left(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y)	
		)
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, Covid1, _Covid2],
		Covid1 = [Covid1X, Covid1Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		Dist_cheb_Covid1 =< 3,
		DiffX is X - Covid1X,
		DiffY is Y - Covid1Y,
		DiffX < 0,
		DiffY > 0,
		(
			move_up_left(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y)	
		)
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, Covid1, _Covid2],
		Covid1 = [Covid1X, Covid1Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		Dist_cheb_Covid1 =< 3,
		DiffX is X - Covid1X,
		DiffY is Y - Covid1Y,
		DiffX == 0,
		DiffY > 0,
		(
			move_up(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y)	
		)
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, Covid1, _Covid2],
		Covid1 = [Covid1X, Covid1Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		Dist_cheb_Covid1 =< 3,
		DiffX is X - Covid1X,
		DiffY is Y - Covid1Y,
		DiffX > 0,
		DiffY > 0,
		(
			move_up_right(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y)		
		)
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, Covid1, _Covid2],
		Covid1 = [Covid1X, Covid1Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		Dist_cheb_Covid1 =< 3,
		DiffX is X - Covid1X,
		DiffY is Y - Covid1Y,
		DiffX > 0,
		DiffY == 0,
		(
			move_right(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, Covid1, _Covid2],
		Covid1 = [Covid1X, Covid1Y],
		distance_chebyshev(X, Y, Covid1X, Covid1Y, Dist_cheb_Covid1),
		Dist_cheb_Covid1 =< 3,
		DiffX is X - Covid1X,
		DiffY is Y - Covid1Y,
		DiffX > 0,
		DiffY < 0,
		(
			move_down_right(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y)		
		)
	);

	%% Go opposite to COVID 2
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, _Covid1, Covid2],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid2 =< 3,
		DiffX is X - Covid2X,
		DiffY is Y - Covid2Y,
		DiffX == 0,
		DiffY < 0,
		(
			move_down(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y)			
		)
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, _Covid1, Covid2],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid2 =< 3,
		DiffX is X - Covid2X,
		DiffY is Y - Covid2Y,
		DiffX < 0,
		DiffY < 0,
		(
			move_down_left(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y)			
		)
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, _Covid1, Covid2],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid2 =< 3,
		DiffX is X - Covid2X,
		DiffY is Y - Covid2Y,
		DiffX < 0,
		DiffY == 0,
		(
			move_left(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y)	
		)
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, _Covid1, Covid2],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid2 =< 3,
		DiffX is X - Covid2X,
		DiffY is Y - Covid2Y,
		DiffX < 0,
		DiffY > 0,
		(
			move_up_left(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y)	
		)
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, _Covid1, Covid2],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid2 =< 3,
		DiffX is X - Covid2X,
		DiffY is Y - Covid2Y,
		DiffX == 0,
		DiffY > 0,
		(
			move_up(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y)	
		)
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, _Covid1, Covid2],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid2 =< 3,
		DiffX is X - Covid2X,
		DiffY is Y - Covid2Y,
		DiffX > 0,
		DiffY > 0,
		(
			move_up_right(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y)		
		)
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, _Covid1, Covid2],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid2 =< 3,
		DiffX is X - Covid2X,
		DiffY is Y - Covid2Y,
		DiffX > 0,
		DiffY == 0,
		(
			move_right(X, Y, Next_X, Next_Y);
			move_down_right(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y)
		)
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, _Covid1, Covid2],
		Covid2 = [Covid2X, Covid2Y],
		distance_chebyshev(X, Y, Covid2X, Covid2Y, Dist_cheb_Covid2),
		Dist_cheb_Covid2 =< 3,
		DiffX is X - Covid2X,
		DiffY is Y - Covid2Y,
		DiffX > 0,
		DiffY < 0,
		(
			move_down_right(X, Y, Next_X, Next_Y);
			move_down(X, Y, Next_X, Next_Y);
			move_right(X, Y, Next_X, Next_Y);
			move_up_right(X, Y, Next_X, Next_Y);
			move_down_left(X, Y, Next_X, Next_Y);
			move_left(X, Y, Next_X, Next_Y);
			move_up(X, Y, Next_X, Next_Y);
			move_up_left(X, Y, Next_X, Next_Y)		
		)
	).

%% move up 
move_up(X, Y, Next_X, Next_Y) :-  
	Next_X is X,
    Next_Y is Y + 1.

%% move diagonally up and right
move_up_right(X, Y, Next_X, Next_Y) :-
	Next_X is X + 1,
    Next_Y is Y + 1.

%% move right
move_right(X, Y, Next_X, Next_Y) :-
	Next_X is X + 1,
    Next_Y is Y.

%% move diagonally down and right
move_down_right(X, Y, Next_X, Next_Y) :-
	Next_X is X + 1,
    Next_Y is Y - 1.

%% move down
move_down(X, Y, Next_X, Next_Y) :-
	Next_X is X,
    Next_Y is Y - 1.

%% move diagonally down and left
move_down_left(X, Y, Next_X, Next_Y) :-
	Next_X is X - 1,
    Next_Y is Y - 1.

%% move left
move_left(X, Y, Next_X, Next_Y) :-
	Next_X is X - 1,
    Next_Y is Y.
 
%% move diagonally up and left
move_up_left(X, Y, Next_X, Next_Y) :-
	Next_X is X - 1,
    Next_Y is Y + 1.


%% ------- BFS rules -------
start_bfs(Data, _Variant) :-	
	get_time(StartTime),
	bfs(Data),
	get_time(EndTime),
	Time is EndTime - StartTime,
	write("4) Time = "), write(Time), write(" seconds"),nl, nl.

bfs(Data) :-
	Data = [MapSize, Actor, Home, _Mask, _Doctor, _Covid1, _Covid2],
	MapSize = [N, M],
	Actor = [ActorX, ActorY],
	Home = [HomeX, HomeY],
	initialize_map(N, M, Map),
	scan_neighbours([[0,0,0]], Map, Data, MapResult, first),
	get_path(ActorX, ActorY, HomeX, HomeY, MapResult, Path),
	second_chance(MapResult, Data, Path, NewPath),
	print_result(NewPath, Data).

second_chance(_Map1, _Data, Path, NewPath) :-
	length(Path, L),
	L > 0,
	NewPath = Path.

second_chance(Map1, Data, Path, NewPath) :-
	length(Path, L),
	L == 0,
	Data = [_MapSize, _Actor, _Home, Mask, Doctor, _Covid1, _Covid2],
	Mask = [MaskX, MaskY],
	Doctor = [DoctorX, DoctorY],
	find_home_from_protection(MaskX, MaskY, Map1, Data, MaskPath),
	find_home_from_protection(DoctorX, DoctorY, Map1, Data, DoctorPath),
	find_total_path(MaskPath, DoctorPath, Map1, Data, NewPath).

find_total_path(MaskPath, DoctorPath, Map1, Data, NewPath) :-
	(
		length(MaskPath, Ml),
		length(DoctorPath, Dl),
		Ml \= 0,
		Dl \= 0,
		Ml < Dl,
		Data = [_MapSize, Actor, _Home, Mask, _Doctor, _Covid1, _Covid2],
		Actor = [ActorX, ActorY],
		Mask = [MaskX, MaskY],
		get_parent(MaskX, MaskY, Map1, MaskParentX, MaskParentY),
		get_path(ActorX, ActorY, MaskParentX, MaskParentY, Map1, PathProtection),
		newlist(PathProtection, MaskPath, NewPath, _Len)
	);
	(
		length(MaskPath, Ml),
		length(DoctorPath, Dl),
		Ml \= 0,
		Dl \= 0,
		Dl < Ml,
		Data = [_MapSize, Actor, _Home, _Mask, Doctor, _Covid1, _Covid2],
		Actor = [ActorX, ActorY],
		Doctor = [DoctorX, DoctorY],
		get_parent(DoctorX, DoctorY, Map1, DoctorParentX, DoctorParentY),
		get_path(ActorX, ActorY, DoctorParentX, DoctorParentY, Map1, PathProtection),
		newlist(PathProtection, DoctorPath, NewPath, _Len)
	);
	(
		length(MaskPath, Ml),
		length(DoctorPath, Dl),
		Ml \= 0,
		Dl == 0,
		Data = [_MapSize, Actor, _Home, Mask, _Doctor, _Covid1, _Covid2],
		Actor = [ActorX, ActorY],
		Mask = [MaskX, MaskY],
		get_parent(MaskX, MaskY, Map1, MaskParentX, MaskParentY),
		get_path(ActorX, ActorY, MaskParentX, MaskParentY, Map1, PathProtection),
		newlist(PathProtection, MaskPath, NewPath, _Len)
	);
	(
		length(MaskPath, Ml),
		length(DoctorPath, Dl),
		Ml == 0,
		Dl \= 0,
		Dl < Ml,
		Data = [_MapSize, Actor, _Home, _Mask, Doctor, _Covid1, _Covid2],
		Actor = [ActorX, ActorY],
		Doctor = [DoctorX, DoctorY],
		get_parent(DoctorX, DoctorY, Map1, DoctorParentX, DoctorParentY),
		get_path(ActorX, ActorY, DoctorParentX, DoctorParentY, Map1, PathProtection),
		newlist(PathProtection, DoctorPath, NewPath, _Len)
	);
	(
		NewPath = []
	).

find_home_from_protection(ProtectionX, ProtectionY, Map1, Data, Path) :-
	(
		Data = [MapSize, _Actor, Home, _Mask, _Doctor, _Covid1, _Covid2],
		MapSize = [N, M],
		Home = [HomeX, HomeY],

		get_parent(ProtectionX, ProtectionY, Map1, ProtectionXParent, ProtectionYParent),
		get_cost(ProtectionX, ProtectionY, Map1, MaskCost),
		ProtectionXParent \= -1,
		ProtectionYParent \= -1,

		initialize_map(N, M, Map2),
		update_cost(ProtectionX, ProtectionY, MaskCost, ProtectionXParent, ProtectionYParent, 1, Map2, Map3, first),

		scan_neighbours([[ProtectionX, ProtectionY, MaskCost]], Map3, Data, MapResult, second),

		get_path(ProtectionX, ProtectionY, HomeX, HomeY, MapResult, Path)
	);
	(
		get_parent(ProtectionX, ProtectionY, Map1, ProtectionXParent, ProtectionYParent),
		ProtectionXParent == -1,
		ProtectionYParent == -1,

		Path = []
	).

initialize_map(N, M, Result) :-
	Max_Length is 4 * max(N, M),
	initialize_map_cell(0, 0, N, M, Max_Length, [], Map),
	update_cost(0, 0, 0, -1, -1, 0, Map, Result, first).

initialize_map_cell(X, Y, N, M, Max_Length, OldMap, Map) :-
	(
		X < N,
		Y < M,
		NewX is X + 1,	
		initialize_map_cell(NewX, Y, N, M, Max_Length, [[X, Y, Max_Length, -1, -1, 0] | OldMap], Map)
	);
	(
		X == N,
		Y < M,
		NewY is Y + 1,
		initialize_map_cell(0, NewY, N, M, Max_Length, OldMap, Map)
	);
	(
		Y == M,
		Map = OldMap
	).

get_path(Xstart, Ystart, Xend, Yend, Map, Path) :- 
	(
		get_parent(Xend, Yend, Map, Xparent, Yparent),
		Xparent \= -1,
		Yparent \= -1,
		restore_path(Xend, Yend, Xstart, Ystart, Map, [[Xend, Yend]], Path)
	);
	(
		get_parent(Xend, Yend, Map, Xparent, Yparent),
		Xparent == -1,
		Yparent == -1,
		Path = []
	).
	
	
restore_path(X, Y, Xdest, Ydest, Map, Cells, Path) :-
	(
		Xdest == X,
		Ydest == Y,
		Path = Cells
	);
	(
		get_parent(X, Y, Map, Xparent, Yparent),
		restore_path(Xparent, Yparent, Xdest, Ydest, Map, [[Xparent, Yparent] | Cells], Path)
	).

get_cost(X, Y, Map, Cost) :-
	(
		Map = [[X, Y, Cost, _Xparent, _Yparent, _Protection] | _T]
	);
	(
		Map = [_ | T],
		get_cost(X, Y, T, Cost)
	).

get_parent(X, Y, Map, Xparent, Yparent) :-
	(
		Map = [[X, Y, _Cost, Xparent, Yparent, _Protection] | _T]
	);
	(
		Map = [_ | T],
		get_parent(X, Y, T, Xparent, Yparent)
	).

get_protection(X, Y, Map, Protection) :-
	(
		Map = [[X, Y, _Cost, _Xparent, _Yparent, Protection] | _T]
	);
	(
		Map = [_ | T],
		get_protection(X, Y, T, Protection)
	).

update_cost(X, Y, Cost, Xparent, Yparent, Protection, Map, NewMap, first) :-
	(
		get_cost(X, Y, Map, CurrentCost),
		CurrentCost > Cost,
		replace_nth0(Map, _I, [X, Y, CurrentCost, _XparentOld, _YparentOld, _ProtectionOld], [X, Y, Cost, Xparent, Yparent, Protection], NewMap)
	);
	(
		get_cost(X, Y, Map, CurrentCost),
		CurrentCost == Cost,
		Protection == 1,
		replace_nth0(Map, _I, [X, Y, CurrentCost, _XparentOld, _YparentOld, _ProtectionOld], [X, Y, Cost, Xparent, Yparent, Protection], NewMap)
	).

update_cost(X, Y, Cost, Xparent, Yparent, Protection, Map, NewMap, second) :-
	get_cost(X, Y, Map, CurrentCost),
	CurrentCost > Cost,
	replace_nth0(Map, _I, [X, Y, CurrentCost, _XparentOld, _YparentOld, _ProtectionOld], [X, Y, Cost, Xparent, Yparent, Protection], NewMap).

valid_cell(X, Y, Protection, Data) :-
	inside_map(X, Y, Data),
	not_covid_affected(X, Y, Data, Protection).

check_cell(X, Y, Xparent, Yparent, Cost, Map, NewMap, Queue, NewQueue, Data, Try) :-
	(
		get_protection(Xparent, Yparent, Map, Protection),
		valid_cell(X, Y, Protection, Data),
		protection_reached(X, Y, Protection, Data, NewProtection),
		update_cost(X, Y, Cost, Xparent, Yparent, NewProtection, Map, NewMap, Try),
		NewQueue = [[X, Y, Cost] | Queue]
	);
	(
		get_protection(Xparent, Yparent, Map, Protection),
		valid_cell(X, Y, Protection, Data),

		protection_reached(X, Y, Protection, Data, NewProtection),
		not(update_cost(X, Y, Cost, Xparent, Yparent, NewProtection, Map, NewMap, Try)),
		NewMap = Map,
		NewQueue = Queue
	);
	(
		not(valid_cell(X, Y, _Protection, Data)),
		NewMap = Map,
		NewQueue = Queue
	).

scan_neighbours(Queue, Map, _Data, MapResult, _Try) :-
	Queue = [],
	MapResult = Map.

scan_neighbours(Queue, Map, Data, MapResult, Try) :-
	Queue = [[X, Y, Cost] | T],
	reverse(T, RestQueue),
	Xprev is X - 1,
	Xnext is X + 1,
	Yprev is Y - 1,
	Ynext is Y + 1,
	NewCost is Cost + 1,

	check_cell(Xprev, Ynext, X, Y, NewCost, Map, NewMap1, RestQueue, NewQueue1, Data, Try),
	check_cell(X, Ynext, X, Y, NewCost, NewMap1, NewMap2, NewQueue1, NewQueue2, Data, Try),
	check_cell(Xnext, Ynext, X, Y, NewCost, NewMap2, NewMap3, NewQueue2, NewQueue3, Data, Try),
	check_cell(Xnext, Y, X, Y, NewCost, NewMap3, NewMap4, NewQueue3, NewQueue4, Data, Try),
	check_cell(Xnext, Yprev, X, Y, NewCost, NewMap4, NewMap5, NewQueue4, NewQueue5, Data, Try),
	check_cell(X, Yprev, X, Y, NewCost, NewMap5, NewMap6, NewQueue5, NewQueue6, Data, Try),
	check_cell(Xprev, Yprev, X, Y, NewCost, NewMap6, NewMap7, NewQueue6, NewQueue7, Data, Try),
	check_cell(Xprev, Y, X, Y, NewCost, NewMap7, NewMap, NewQueue7, NewQueue8, Data, Try),

	reverse(NewQueue8, NewQueue),
	scan_neighbours(NewQueue, NewMap, Data, MapResult, Try).

print_result(Path, Data) :-
	(
		length(Path, L),
		L \= 0,
		Steps is L - 1,
		write("1) Win."), nl,
		write("2) The number of steps: "), write(Steps), nl,
		write("3) The path: "), write(Path), nl,
		once(print_map(Data, Path)), !	
	);
	(
		length(Path, L),
		L == 0,
		write("1) Lose."), nl
	).

%% Took from here
%% https://www.swi-prolog.org/pldoc/doc_for?object=nth0/4
replace_nth0(List, Index, OldElem, NewElem, NewList) :-
   nth0(Index, List, OldElem, Transfer),
   nth0(Index, NewList, NewElem, Transfer).

%% Took from here
%% https://stackoverflow.com/questions/15018398/prolog-combining-two-lists
newlist([], List, List, X) :-
	length(List, X).

newlist([Element|List1],List2,[Element|List3],L) :- 
	newlist(List1, List2, List3, LT), L is LT + 1.


%% ---------- Additional stuff ----------

%% Parse input data
input(Input, Data) :-
	%% Data with input coordinates for each agent
	(
		Input = [N, M, [ActorX, ActorY], [HomeX, HomeY], [MaskX, MaskY], [DoctorX, DoctorY], [Covid1X, Covid1Y], [Covid2X, Covid2Y]],
		
		Map = [N, M],
		Actor = [ActorX, ActorY],
		Home = [HomeX, HomeY],
		Mask = [MaskX, MaskY],
		Doctor = [DoctorX, DoctorY],
		Covid1 = [Covid1X, Covid1Y],
		Covid2 = [Covid2X, Covid2Y],

		Data = [Map, Actor, Home, Mask, Doctor, Covid1, Covid2]
	);
	%% Input with only map size. Other data will be generated randomly
	(
		%% Case when agents can't be placed on the map all together
		(
			Input = [N, M],
			N =< 3,
			M =< 3,
			write("Impossible to generate!"), nl,
			fail
		);
		%% Generate the map and check if it is valid
		(
			Input = [N, M],
			N > 3,
			M > 3,
			repeat,
			(
				generate_map(N, M, Data),
				valid_map(Data),
				!
			)
		)
	).

%% Map generation
generate_map(N, M, Data) :-
	ActorX is 0,
	ActorY is 0,
	random(0, N, HomeX),
	random(0, M, HomeY),
	random(0, N, MaskX),
	random(0, M, MaskY),
	random(0, N, DoctorX),
	random(0, M, DoctorY),
	random(0, N, Covid1X),
	random(0, M, Covid1Y),
	random(0, N, Covid2X),
	random(0, M, Covid2Y),

	Map = [N, M],
	Actor = [ActorX, ActorY],
	Home = [HomeX, HomeY],
	Mask = [MaskX, MaskY],
	Doctor = [DoctorX, DoctorY],
	Covid1 = [Covid1X, Covid1Y],
	Covid2 = [Covid2X, Covid2Y],
	Data = [Map, Actor, Home, Mask, Doctor, Covid1, Covid2].

%% Check if agentss are on different cells, inside the map, 
%% and the actor, doctor and mask are not in the COVID zone 
valid_map(Data) :-
	Data = [_Map, Actor, Home, Mask, Doctor, Covid1, Covid2],
	Actor = [ActorX, ActorY],
	Home = [HomeX, HomeY],
	Mask = [MaskX, MaskY],
	Doctor = [DoctorX, DoctorY],
	Covid1 = [Covid1X, Covid1Y],
	Covid2 = [Covid2X, Covid2Y],

	ActorX == 0,
	ActorY == 0,
	inside_map(HomeX, HomeY, Data),
	inside_map(MaskX, MaskY, Data),
	inside_map(DoctorX, DoctorY, Data),
	inside_map(Covid1X, Covid1Y, Data),
	inside_map(Covid2X, Covid2Y, Data),

	not(on_same_cell(ActorX, ActorY, HomeX, HomeY)),
	not(on_same_cell(ActorX, ActorY, MaskX, MaskY)),
	not(on_same_cell(ActorX, ActorY, DoctorX, DoctorY)),
	not(on_same_cell(HomeX, HomeY, MaskX, MaskY)),
	not(on_same_cell(HomeX, HomeY, DoctorX, DoctorY)),
	not(on_same_cell(MaskX, MaskY, DoctorX, DoctorY)),
	not(on_same_cell(Covid1X, Covid1Y, Covid2X, Covid2Y)),

	not_in_covid_area(ActorX, ActorY, Covid1X, Covid1Y),
	not_in_covid_area(ActorX, ActorY, Covid2X, Covid2Y),
	not_in_covid_area(HomeX, HomeY, Covid1X, Covid1Y),
	not_in_covid_area(HomeX, HomeY, Covid2X, Covid2Y),
	not_in_covid_area(MaskX, MaskY, Covid1X, Covid1Y),
	not_in_covid_area(MaskX, MaskY, Covid2X, Covid2Y),
	not_in_covid_area(DoctorX, DoctorY, Covid1X, Covid1Y),
	not_in_covid_area(DoctorX, DoctorY, Covid2X, Covid2Y).

print_data(Data) :-
	Data = [Map, Actor, Home, Mask, Doctor, Covid1, Covid2],
	write("Map size [N:M] = "), write(Map), nl,
	write("Actor = "), write(Actor), nl,
	write("Home = "), write(Home), nl,
	write("Mask = "), write(Mask), nl,
	write("Doctor = "), write(Doctor), nl,
	write("Covid1 = "), write(Covid1), nl,
	write("Covid2 = "), write(Covid2), nl, nl.

%% print graphically the map denoting agents with special symbols:
%% A - actor, H - home, D - doctor, M - mask, C - COVID
%% * - free cell
%% the path is denoted with 'x' symbol 
print_map(Data, Path) :-
	Data = [Map, _Actor, _Home, _Mask, _Doctor, _Covid1, _Covid2],
	Map = [_N, M],
	Y is M - 1,
	print_map_cell(0, Y, Data, Path).

print_map_cell(X, Y, Data, Path) :-
	(
		Data = [Map, _Actor, _Home, _Mask, _Doctor, _Covid1, _Covid2],
		Map = [N, _M],
		X < N,
		Y >= 0,
		print_cell(X, Y, Data, Path),
		NewX is X + 1,
		print_map_cell(NewX, Y, Data, Path)
	);
	(
		Data = [Map, _Actor, _Home, _Mask, _Doctor, _Covid1, _Covid2],
		Map = [N, _M],
		X == N,
		Y >= 0,
		nl,
		NewY is Y - 1,
		print_map_cell(0, NewY, Data, Path)
	);
	(	
		Data = [Map, _Actor, _Home, _Mask, _Doctor, _Covid1, _Covid2],
		Map = [N, _M],
		EndX is N - 1,
		X == EndX,
		Y == 0,
		nl, !
	).

print_cell(X, Y, Data, Path) :-
	(
		Data = [_Map, Actor, _Home, _Mask, _Doctor, _Covid1, _Covid2],
		Actor = [ActorX, ActorY],
		on_same_cell(X, Y, ActorX, ActorY),
		write("A ")
	);
	(
		Data = [_Map, _Actor, Home, _Mask, _Doctor, _Covid1, _Covid2],
		Home = [HomeX, HomeY],
		on_same_cell(X, Y, HomeX, HomeY),
		write("H ")
	);
	(
		Position = [X, Y],
		member(Position, Path),
		write("x ")
	);
	(
		Data = [_Map, _Actor, _Home, Mask, _Doctor, _Covid1, _Covid2],
		Mask = [MaskX, MaskY],
		on_same_cell(X, Y, MaskX, MaskY),
		write("M ")
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, Doctor, _Covid1, _Covid2],
		Doctor = [DoctorX, DoctorY],
		on_same_cell(X, Y, DoctorX, DoctorY),
		write("D ")
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, Covid1, _Covid2],
		Covid1 = [Covid1X, Covid1Y],
		on_same_cell(X, Y, Covid1X, Covid1Y),
		write("C ")
	);
	(
		Data = [_Map, _Actor, _Home, _Mask, _Doctor, _Covid1, Covid2],
		Covid2 = [Covid2X, Covid2Y],
		on_same_cell(X, Y, Covid2X, Covid2Y),
		write("C ")
	);
	(
		write("* ")
	).
