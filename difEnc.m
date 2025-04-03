function EBits =  difEnc( Bits, k, dbg )
%function EBits =  difEnc( Bits, k )
%	implements differential encoding of bits: ei = ei-1 + bi 
%	Bits is a matrix of parallel blocks - columns processed independently
%		expected type: logical
%	assuming zero-th bit is 0
%	optional k (default == 1) defines processing by blocks of k bits for higher order modulations
%		Bits may be	- a 3D volume for custom modulation implementation
%					- a 2D matrix for compatibility with toolbox qammod function
%	see also: difDec

	if nargin == 0
		EBits = unitTest() ;
		return ;
	end
	if nargin < 3
		dbg = false ;
	end
	if nargin < 2
		k = 1 ;
	end
	
	[ y, x, z ] = size( Bits ) ;
	if k == 1 
		EBits = zeros( y , x, 'logical' ) ;
		EBits( 1, : ) = Bits( 1, : ) ; %assuming zero-th E-bit is zero :)
		for r = 2 : y 
			EBits( r , : ) = xor( EBits( r - 1, : ), Bits( r, : ) ) ;
		end
	else
		if z == 1
			%perform reshaping to 3D volume
			[ q, r ] = divmod( y, k ) ;
			if( r ~= 0 )
				error( 'number of bits in column not divisible by k' ) ;
			end
			T	 = reshape( Bits, k, q, x ) ;
			Bits = permute( T, [ 2 3 1 ] ) ; %inv perm [ 3 1 2 ]
		else
			q = y ;
		end
		if( k ~= size( Bits, 3 ) )
			error('bits per symbol different than Z dimension') ;
		end
		if dbg
			%debug only - just return reshaped array for a check
			EBits = Bits ;
			return ;
		end
		EBits = zeros( q, x, k, 'logical' ) ;
		EBits( 1, :, : ) = Bits( 1, :, : ) ; %assuming zero-th E-bit is zero
		for r = 2 : q 
			EBits( r , :, : ) = xor( EBits( r - 1, :, : ), Bits( r, :, : ) ) ;
		end	
		if z == 1 
			%reshape back to 2 dimensions
			T		= permute( EBits, [ 3 1 2 ] ) ;
			EBits	= double( reshape( T, k * q, x, 1 ) ) ; 
		end
	end
end

function OK = unitTest()
	%test reshaping bits from 2D to 3D where each k-bit subvector will be mapped to single prototype
	OK = true ;

	k	= 2 ;
	A	= [ 1 1 ; 0 1 ; 1 0 ; 0 0 ; 0 0 ; 0 1 ]
	OK	= OK && testReshape( A, k ) ;

	k = 4 ;
	q = 3 ;
	M = q * k ;
	N = 3 ;	
	A	= randi( [ 0 1 ], M , N ) 
	OK	= OK && testReshape( A, k ) ;
	OK	= OK && testDifEncDec1D() ;
	OK	= OK && testDifEncDec3D() ;
	OK	= OK && testDifEncDec2D() ;
	OK	= OK && testDifEncDec2Dk4() ;
	OK	= OK && testDifEncDec3Dk4() ;

	if OK
		fprintf("UNIT TEST PASSED\n") ;
	else
		fprintf("UNIT TEST FAILED\n") ;
	end
end

function OK = testReshape( A, k )
	[ M, N ] = size( A ) ;
	q = divmod( M, k ) ;

	B = difEnc( A, k, true ) 
	for j = 1 : N
		for i = 1 : q
			U = A( ( i - 1 ) * k + 1 : i * k , 1 ) ;
			V = squeeze( B( i , 1, : ) ) ;
			if ~isequal( U, V )
				OK = false ;
				fprintf("reshape test FAILED\n") ;
				return ;
			end
		end
	end
	fprintf("reshape test PASSED\n") ;
	OK = true ;
end


function OK = testDifEncDec1D()
	k = 1 ;
	A = [ 1 1 ; 0 1 ; 1 0 ; 0 0 ; 0 0 ; 0 1 ]
	B = difEnc( A, k ) 
	C = difDec( B, k )
	if isequal( A, C ) 
		fprintf("test Dif Encode +Decode 1D PASSED\n") ;
		OK = true ;
	else
		fprintf("test Dif Encode +Decode 1D FAILED\n") ;
		OK = false ;
	end
end

function OK = testDifEncDec3D()
	k = 2 ;
	A = [ 1 1 ; 0 1 ; 1 0 ; 0 0 ; 0 0 ; 0 1 ]
	B = difEnc( A, k, true )	%should be 3D - just reshaped
	C = difEnc( B, k )			%should be 3D - diff encoded
	D = difDec( C, k )			%should be 3D - diff decoded
	if isequal( B, D ) 
		fprintf("test Dif Encode +Decode 3D PASSED\n") ;
		OK = true ;
	else
		fprintf("test Dif Encode +Decode 3D FAILED\n") ;
		OK = false ;
	end
end

function OK = testDifEncDec2D()
	k = 2 ;
	A = [ 1 1 ; 0 1 ; 1 0 ; 0 0 ; 0 0 ; 0 1 ]
	B = difEnc( A, k )	
	C = difDec( B, k )	
	
	if isequal( A, C ) 
		fprintf("test Dif Encode+Decode 2D PASSED\n") ;
		OK = true ;
	else
		fprintf("test Dif Encode+Decode 2D FAILED\n") ;
		OK = false ;
	end
end

function OK = testDifEncDec3Dk4()
	k = 4 ;
	q = 3 ;
	M = q * k ;
	N = 3 ;	
	A = randi( [ 0 1 ], M, N ) 
	B = difEnc( A, k, true )	%should be 3D - just reshaped
	C = difEnc( B, k )			%should be 3D - diff encoded
	D = difDec( C, k )			%should be 3D - diff decoded
	if isequal( B, D ) 
		fprintf("test Dif Encode+Decode k = 4 3D PASSED\n") ;
		OK = true ;
	else
		fprintf("test Dif Encode+Decode k = 4 3D FAILED\n") ;
		OK = false ;
	end
end

function OK = testDifEncDec2Dk4()
	k = 4 ;
	q = 3 ;
	M = q * k ;
	N = 3 ;	
	A = randi( [ 0 1 ], M, N ) 
	B = difEnc( A, k )
	C = difDec( B, k )
	if isequal( A, C ) 
		fprintf("test Dif Encode+Decode k = 4 2D PASSED\n") ;
		OK = true ;
	else
		fprintf("test Dif Encode+Decode k = 4 2D FAILED\n") ;
		OK = false ;
	end
end