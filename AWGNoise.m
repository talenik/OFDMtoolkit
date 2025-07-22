function [ NOISE, vm ] = AWGNoise( dim, vChan, type )
% [ NOISE, vm ] = AWGNoise( dim, vChan [, type ] )
%	generates AWGN noise based on the EbNo assuming unit signal power
%	dim		- dimension vector of the output vector/matrix/volume
%	vChan	- desired noise variance
%	type	- 'real' (default) for real-valued noise
%			- 'complex' for complex-valued noise
%	returns:
%		NOISE	- real or complex valued scalar/vector/matrix/volume
%				  assuming uncorrelated Re and Im parts (cov(Re,Im) == 0)
%		vm		- measured noise variance

if nargin == 0
	unittest() ;
	NOISE	= NaN ;
	vm		= NaN ;
	return ;
end

if nargin < 3
	type = 'real' ;
end

chan.sigma	= sqrt( vChan ) ;

if isequal( type, 'complex')
	Nr		= ( chan.sigma / sqrt( 2 ) ) * randn( dim ) ;
	Ni		= ( chan.sigma / sqrt( 2 ) ) * randn( dim ) ;
	%Sklar Appendix C: 2D signal space > 2 correlators. each full variance
	%Nr		= ( chan.sigma ) * randn( dim ) ;
	%Ni		= ( chan.sigma ) * randn( dim ) ;
	NOISE	= Nr + i * Ni ;
	nc		= cov( Nr( : ), Ni( : ) ) ;	%covariance between real and imaginary part
	assert( abs( nc( 1, 2 ) ) < 1e-2 ) ;
elseif isequal( type, 'real')
	NOISE	= chan.sigma * randn( dim ) ;
else
	error('type error') ;
end

vm = var( NOISE, 0, 'all' ) ;

end

function unittest()
tol = 1e-3
N	= 10000 ;
dim = [ N N ] ;
% real-valued noise:
	[ NOISE, vm ] = AWGNoise( dim, 1 ) ; vm
	[ ok, ~, de ] = equals( vm, 1, tol ) 
	[ NOISE, vm ] = AWGNoise( dim, 3 ) ; vm
	[ ok, ~, de ] = equals( vm, 3, tol )
% complex-valued noise:	
	[ NOISE, vm ] = AWGNoise( dim, 1, 'complex' ) ; vm
	[ ok, ~, de ] = equals( vm, 1, tol )
	[ NOISE, vm ] = AWGNoise( dim, 3, 'complex' ) ; vm
	[ ok, ~, de ] = equals( vm, 3, tol )

end