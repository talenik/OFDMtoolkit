function [ Hn, Tms ] = impulseResponse( NP, Nmax )
% Hn = impulseResponse( NP, Nmax )
%	create a complex impulse response simulatin NP paths, but given a precise
%	length Nmax in samples. It is expected that Tm >> NP (e.g. 10 times )
	if nargin == 0
		unit_test() ;
		Hn = nan ;
		return ;
	end

	assert( Nmax > NP ) ;
	Hn	= impulseR( NP ) ;
	Tms = size( Hn, 1 ) ;
	T	= [ 1 : 1 : Tms ]' ;
	Ti	= linspace( 0, Tms, Nmax )' ;
	H   = interp1( T, Hn, Ti, 'spline' ) ;
	Hn	= normalize( H ) ; 
	Tms = size( H, 1 ) ;
end

function [ Hn ] = impulseR( Tm )
	H	= randnc( Tm, 1 ) ;
	Hn	= normalize( H ) ;
end

function Vn = normalize( V )
%assuming V is a complex valued column vector
	E	= V' * V ;
	assert( isreal( E ) ) ;
	Vn = V .* ( 1 / sqrt( E ) ) ;
end


function unit_test()
	% N	= 1024
	% Hn	= impulseResponse( 11 ) ;
	% 
	% Hk	= ( 1 /sqrt( N ) ) * fft( Hn, N ) ;
	% plotTF( Hn, Hk ) ;
	% 
	% Tms = size( Hn, 1 ) ;
	% T	= [ 1 : 1 : Tms ] ;
	% Ns	= 10 * Tms ;
	% Ti	= linspace( 0, Tms, Ns ) ;
	% whos
	% 
	% Hni  = interp1( T, Hn, Ti, 'spline' ) ;
	% Hki	= ( 1 /sqrt( N ) ) * fft( Hni, N ) ;
	% plotTF( Hni, Hki ) ;
	% 
	% whos 

	NP = 11 ;
	Ns = 128 ;
	Hn = impulseResponse( NP, Ns ) ;
	whos
	assert( size( Hn, 1 ) == Ns ) ;
	assert( isreal( Hn ) == false ) ;
	
	N = 1024 ;
	Hk	= ( 1 /sqrt( N ) ) * fft( Hn, N ) ;
	plotTF( Hn, Hk ) ;
end