function [ PdB, P ] = sigPower( S, all )
%function [ PdB, P ] = power( S [ , all ] )
%	calculate signal power in dB and linear scale, column-wise by default
%		S is a potentially complex valued vector or matrix
%		all - if set, calculate power based on all matrix elements
%	output:
%		PdB - signal power in dB
%		P	- signal power in linear scale

if nargin < 2 
	all = false ;
end

[ y, x ] = size( S ) ;

if x == 1 || y == 1
	N = length( S ) ;
else
	N = y ;	%calculate power column-wise
end

if all
	S = S( : ) ;
	N = length( S ) ;
end

P	= sum( S .* conj( S ) ) / N ;
PdB = 10 * log10( P ) ;