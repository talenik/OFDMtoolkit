function H = LDPCExpandH( Hbm, z )
% Exercise 10.9:
% Uncompress the model matrix Hbm to binary sparse matrix H.
%	Hbm		- model matrix specifies H in a compressed integer format.
% 	z		- tier (submatrix) size
% returns:
%	H		- binary parity check matrix of size M x N

	[ mb, nb ] = size( Hbm ) ;
	N = nb * z ;
	M = mb * z ;

	%construct the binary parity check matrix
	H = zeros( M, N ) ;
	Iz = eye( z ) ;

	for r = 1 : 1 : mb
		for c = 1 : 1 : nb
			shift = Hbm( r, c ) ;

			%only fill code in this area - leave everything else untouched ----
			% Exercise: complete the code to obtain required functionality
			if shift == -1
				continue ;
			elseif shift == 0
				stamp = Iz ; 
			else
				stamp 	= cyclicShiftMatrix( z, shift ) ;
			end
			H( ( ( r - 1 ) * z ) + 1 : r * z, ( ( c - 1 ) * z ) + 1 : c * z ) = stamp ;
			%------------------------------------------------------------------
		end
	end
end

function M = cyclicShiftMatrix( Size, shift )

    if shift < 0
	    %implement left shift as negative shift
	    shift = Size + shift ;
    end 
    
    shift	= mod( shift, Size ) ;
    
    Perm	= cyclicShiftRight( [ 1 : Size ], -shift ) ;
    I		= eye( Size ) ;
    M		= I( :, Perm ) ;
end

function rotated = cyclicShiftRight( M, shift )

    [ y, x ] = size( M ) ;
    
    if y > 1 && x == 1
	    %column vector
	    n = y ;
    else
	    %row vector or matrix
	    n = x ;
    end
    
    if shift < 0
	    %implement left shift as negative shift
	    shift = n + shift ;
    end 
    
    shift	= mod( shift, n ) ;
    s		= n - shift ;
    
    if y > 1 && x == 1
	    %column vector
	    rotated = [ M( s + 1 : end ) ; M( 1 : s ) ] ;
    else
	    rotated = [ M( :, s + 1 : end ) M( :, 1 : s ) ] ;
    end
end

	