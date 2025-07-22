function [ Rn, va ] = randnc( m, n, PdB )
%function [ Rn, va ]  = randnc( m, n [, PdB] )
%	generate a matrix of complex random numbers 
%	drawn from the zero-mean normal distribution
%	with half power in each component
%	with optional Power specified in dB 	

	if nargin == 0
		unittest() ;
		Rn = nan ;
		va = nan ;
		return ;
	end

	if nargin < 3 
		PdB = 0 ;
	end
	
	if nargin < 2
		n = 1 ;
	end
	P 	= 10 ^ ( PdB / 10 ) ; 
	v 	= P ; 
	
	Rn	= sqrt( v / 2 ) * randn( m, n ) + i * sqrt( v / 2 ) * randn( m, n ) ;
	va	= var( Rn, 0, 'all') ;
end

function ok = test( Pd )
	N	= 1000 ;
	[ R, va ] = randnc( N, N, Pd ) ;
	Ps = sigPower(R, 'all')
	vr = var( real( R ), 0, 'all' ) ;
	vi = var( imag( R ), 0, 'all' ) ;
	fprintf("desired Power:%g [dB], sigPower: %g [dB], actual var:%g, realvar: %g, imagvar: %g  \n", Pd, Ps, va, vr, vi ) ;
	ok = true ;
end

function unittest()
	test( 0 )
	test( 1 )
	test( 10 )
	test( 100 )

end
