function power = checkPower( Signal, ev, tol )
%function power = checkPower( Signal, ev, tol )
%	test that signl average power is equal to some value 
%	statistical equality with tolerance - won't work with small Signal dimensions

[ pdB, power ]	= sigPower( Signal, 'all' ) ;
if ~equals( power, ev, tol ) 
	error('Signal average power not %4.2f, actualy: %4.2f, tolerance: %4.2f \n', ev, power, tol ) ;
end