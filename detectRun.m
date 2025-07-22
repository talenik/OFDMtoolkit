function run = detectRun( V, val, len )
% run = detectRun( V, val, len )
%	detect a run of length at least len of values val i vector V

if nargin == 0
	unit_test() ;
	run = nan ;
	return ;
end

	ind = find( V == val ) ;
	if isempty( ind )
		run = false ;
	elseif len == 1
		%just detect single value- TODO detect it isolation
		run = true ;
	else
		d = diff( ind ) ; 
		if nnz( d == 1 ) >= 1
			run = true ;
		else
			run = false ;
		end
	end
end

function unit_test()
	detectRun( [1 2 3 4 4 2 1 2 2 2 3 ], 2, 2 )
	detectRun( [1 2 3 4 4 2 1 2 2 3 ], 4, 2 )
	detectRun( [1 2 3 4 4 2 1 2 2 3 ], 2, 2 )
	detectRun( [1 2 3 4 2 1 2 3 ], 2, 2 )	
end

