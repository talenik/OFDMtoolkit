function [ val, tax, sum ] = findIntMultiple( maxsum, q, tol )

A = [ maxsum : -1 : 1 ] ;
B = q .* A ;

pot = findInt( B, tol ) ;

	for i = 1 : length( pot )
		val = pot( i ) / q ;
		tax = q * val ;
		sum	= val + tax ;
		if sum <= maxsum
			return 
		end
	
	end

	val = 0 ;
	tax = 0 ;
	sum = 0 ;
end

function r = findInt( M, tol )

	if nargin == 1
		tol = 1e-10 ;
	end
	
	R = round( M, 0 ) ;
	D = abs( R - M ) ;
	i =  D < tol  ;
	
	r = M( i ) ;
end


