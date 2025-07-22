%simulation to evaluate PAPR in an IEEE 802.11a/g-like OFDM transmission
% simulate forming of an OFDM frame 
% and statistical evaluation of PAPR, comparing to theoretical values
%
% parameters: A, N, M where:
%	A - is the minumal symbol amplituded in a square QAM constellation
%	N - is the FFT size
%	M - the QAM order, must be a square 4, 16, 64, ...
% known limitations (TODO):
%	Ignoring pilots, preamble and zero-vlaued guard subcarrietrs for now

clear ; clc ;
format compact ;

%params for IEEE 802.11a/g
m.Nc	= 52 ;					%usefull subcarriers
m.N		= 64 ;					%FFT size
m.P		= 4 ;					%pilot subcarriers
m.Nd	= m.Nc - m.P ;			%data subcarriers
m.PS	= m.Nd / m.P ;			%pilot spacing - how many subcarriers between pilots
m.G		= m.N - ( m.Nc + 1 ) ;	%guard zero subcarriers
m.GL	= ceil( m.G / 2 ) ;		%lower guard subc
m.GH	= floor( m.G / 2 ) ;	%upper guard subc
m.FPI	= m.GL + ( m.PS / 2 ) ;	%first pilot index 

m.STF = sqrt( 13 / 6 ) * [ 0, 0, 1+j, 0, 0, 0, -1-1i, 0, 0, 0, 1+j, 0, 0, 0, -1-j, 0, 0, 0, -1-j, 0, 0, 0, 1+j, 0, 0, 0, 0, 0, 0, 0, -1-j, 0, 0, 0, -1-j, 0, 0, 0, 1+j, 0, 0, 0, 1+j, 0, 0, 0, 1+j, 0, 0, 0, 1+j, 0, 0 ] ;
m.LTF = [ 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 0, 1, -1, -1, 1, 1, -1, 1, -1, 1, -1, -1, -1, -1, -1, 1, 1, -1, -1, 1, -1, 1, -1, 1, 1, 1, 1 ] ;

m.STFP = [ zeros( 1, m.GL ) m.STF zeros( 1, m.GH ) ] ;
m.LTFP = [ zeros( 1, m.GL ) m.LTF zeros( 1, m.GH ) ] ;

assert( length( m.STFP ) == m.N ) ;
assert( length( m.LTFP ) == m.N ) ;
assert( isInt( m.PS ) ) ;
assert( isInt( m.FPI ) ) ;

%DEBUG: plot constallation with symbol mapping
%M = 1024 ; y = qammod( [ 0 : M - 1 ], M, PlotConstellation = true ) ;


%% run the calculations
global debug ;
debug = false ;
clc ;
[ Ppeak, Pavg, PAPRnm, PAPRdB ] = PAPR_teoretical( 1024, 16, 1 )
[ Ppeak, Pavg, PAPRnm, PAPRdB ] = PAPR_worstcase( 1024, 16, 1 )


%% calculate table for various parameters
debug = false ;
N = [ 64 128 256 512 1024 ] ;
M = [ 4 16 64 256 1024 ] ;
PAPR_TABLE_THEO = zeros( length( N ), length( M ) ) ;
PAPR_TABLE_WORS = zeros( length( N ), length( M ) ) ;
PAPR_TABLE_STAT = zeros( length( N ), length( M ) ) ;
Nos = 10000 ;

% debug = true ;
% N = 512
% M = 64
% Nos = 100

A	= 1 ; 

for n = 1 : length( N )
	for m = 1 : length( M )
		[ Ppeak, Pavg, PAPRnm, PAPRdB ] = PAPR_teoretical( N( n ), M( m ), A ) ;
		PAPR_TABLE_THEO( n, m ) = PAPRdB ;

		[ Ppeak, Pavg, PAPRnm, PAPRdB ] = PAPR_worstcase( N( n ), M( m ), A ) ;
		PAPR_TABLE_WORS( n, m ) = PAPRdB ;
		
		PAPR_TABLE_STAT( n, m ) =  OFDM_PAPR_stat( A, N( n ), M( m ), Nos ) ;
	end
	fprintf("N = %4d, QAM-M:%5d, %5d, %5d, %5d, %5d \n", N( n ), M ) ;
	fprintf("PAPRdB TEORY: \t%6.3f, %6.3f, %6.3f, %6.3f, %6.3f\n", PAPR_TABLE_THEO( n, : ) ) ;
	fprintf("PAPRdB WORST: \t%6.3f, %6.3f, %6.3f, %6.3f, %6.3f\n", PAPR_TABLE_WORS( n, : ) ) ;
	fprintf("PAPRdB STAT : \t%6.3f, %6.3f, %6.3f, %6.3f, %6.3f\n", PAPR_TABLE_STAT( n, : ) ) ;
end



function [ PAPRedB ] =  OFDM_PAPR_stat( A, N, M, OS )
%bits are random generated, current approximation ignores preamble and pilots
global debug ;

	if debug
		fprintf( 'PAPR for A: %5.2f, QAM-M: %d, subcarriers N: %d, Nr. OFDM symbols:%d\n', A, M, N, OS ) ;
	end

	%calculating average signal power based on random data
	DATA	= randi( [ 0 ( M - 1 ) ], N, OS ) ;
	SS		= qammod( DATA, M ) ;
	%sscatter( SS ) ; whos ;

	FREQ	= SS ;
	POWF	= ( 1 / 2 ) * FREQ .* conj( FREQ ) ;
	TIME	= sqrt( N ) * ifft( FREQ, N, 1 ) ;
	POWT	= TIME .* conj( TIME ) ;
	assert( isreal( POWF ) ) ;
	assert( isreal( POWT ) ) ;
	%these two are functions of OFDM symbol - column
	PpeakT	= max( POWT ) ;
	PavgT	= mean( POWT ) ;

	PPmean	= mean( PpeakT ) ;
	PAmean	= mean( PavgT ) ;
	PPvar	= var( PpeakT ) ;
	PAvar	= var( PavgT ) ;
	PAPRe	= PPmean / PAmean ;
	PAPRedB = todB( PAPRe ) ;

	if debug 
		figure() ;
		plot( [ 1 : OS ], [ PpeakT ; PavgT ] ) ;
		fprintf('experimental obtained by statistics, these should not even approach PAPRmax:\n') ;
		fprintf('Ppeak: %5.2f, Pavg: %5.2f, PAPR [dB]: %5.2f \n', PPmean, PAmean, PAPRedB ) ;
	end

end


function [ Ppeak, Pavg, PAPR, PAPRdB ] = PAPR_teoretical( N, M, A )
%[ Ppeak, Pavg, PAPR, PAPRdB ] = PAPR_teoretical( N, M [,A] )
%	calculates OFDM peak ang avg powers based on theretical formulas
%	N - FFT size (assuming equal to nr. of subcarriers)
%	M - QAM modulation order
%		valid for squre QAM constellations:
%		M = m^2 such as: 4, 16, 256, ...
global debug ;

	if nargin < 3
		A = 1 ;
	end
	if ~isInt( sqrt( M ) ) 
		warning('M must be a square') ;
	end
	P0		= A ^ 2 ;
	Pavgsc	= ( 1 / 3 ) * ( M - 1 ) * P0 ;
	Ppeak	= ( N ^ 2 ) * ( ( sqrt( M ) - 1 ) ^ 2 ) * P0 ; %eq. 125
	Pavg	= N * Pavgsc ;
	PAPR	= Ppeak / Pavg ;
	PAPRdB	= todB( PAPR ) ;

	if debug
		figure() ; 
		fprintf('Maximal PAPR values, theoretical calculation:\n ') ;
		fprintf('Ppeak: %5.2f, Pavg: %5.2f, PAPR: %5.2f, PAPR [dB]: %5.2f \n', Ppeak, Pavg, PAPR, PAPRdB ) ;
	end
 end

function [ Ppeak, Pavg, PAPR, PAPRdB ] = PAPR_worstcase( N, M, A )
global debug ;

	%calculating peak signal power based on extreme data
	%select largest-amplitude DATA value - see doc qammmod
	%these are: 2 for 4-QAM, 8 for 16-QAM, 32 for 64-QAM, 128 for 256-QAM, 512 for 1024-QAM
	DATA	= A * ( M / 2 ) * ones( N, 1 ) ;
	SS		= qammod( DATA, M ) ;
	FREQ	= SS ;
	POWF	= ( 1 / 2 ) * FREQ .* conj( FREQ ) ;	%power at each freq bin
	TIME	= sqrt( N ) * ifft( FREQ, N, 1 ) ;			%unitary IFFT preserves power
	POWT	= TIME .* conj( TIME ) ;				%this is the signal of interest

	Ppeak	= max( POWT ) ;
	Pavg	= mean( POWT ) ;  
	PAPR	= Ppeak / Pavg ;	
	PAPRdB	= todB( PAPR ) ;

	if debug
		figure() ; 
		plotTF( TIME, FREQ ) ;
		fprintf('Worst case values, obtained by experiment:\n ') ;
		fprintf('Ppeak: %5.2f, Pavg: %5.2f, PAPR: %5.2f, PAPR [dB]: %5.2f \n', Ppeak, Pavg, PAPR, PAPRdB ) ;
		FREQ(1:5)
	end
end





function plotTF( Xt, Xf ) 
	figure ;
	subplot( 1, 2, 1 ) ;
	stem( abs( Xt ) ) ;
	subplot( 1, 2, 2 ) ;
	stem( abs( Xf ) ) ;
end