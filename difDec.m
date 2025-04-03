function Bits = difDec( DBits, k )
%function Bits = difDec( DBits, k )
%	implement differential decoding bi = ei + ei-1
%		DBits is a matrix of parallel blocks - columns processed independently
%			expected type: logical
%		assuming zeroth Ebit is 0
%	optional k (default == 1) defines processing by blocks of k bits for higher order modulations
%		Bits may be	- a 3D volume for custom modulation implementation
%					- a 2D matrix for compatibility with toolbox qammod function
%	see also: difEnc

if nargin < 2
	k = 1 ;
end

if k == 1
	x		= size( DBits, 2 ) ; 
	SBits	= [ zeros( 1, x, 'logical' ) ; DBits ] ;
	Bits	= [ DBits ; zeros( 1, x, 'logical' ) ] ;
	Bits	= xor( Bits, SBits ) ;
	Bits	= Bits( 1 : end - 1, : ) ; 
else
	[ y, x, z ] = size( DBits ) ; %assuming 3D volume
	if z == 1
		%reshape from 2D to 3D
		[ q, r ] = divmod( y, k ) ;
		if( r ~= 0 )
			error( 'number of bits in column not divisible by k' ) ;
		end
		T	 = reshape( DBits, k, q, x ) ;
		DBits = permute( T, [ 2 3 1 ] ) ; %inv perm [ 3 1 2 ]
	else
		q = y ;
		if z ~= k
			error('z dimension must be equal to k') ;
		end
	end
	if size( DBits, 3 ) ~= k
		error('z dimension not equal to k') ;
	end
	SBits	= [ zeros( 1, x, k, 'logical' ) ; DBits ] ;
	Bits	= [ DBits ; zeros( 1, x, k, 'logical' ) ] ;
	Bits	= xor( Bits, SBits ) ;
	Bits	= Bits( 1 : end - 1, :, : ) ; 
	if z == 1 
		%reshape back to 2 dimensions
		T		= permute( Bits, [ 3 1 2 ] ) ;
		Bits	= reshape( T, k * q, x, 1 ) ; 
	end
end