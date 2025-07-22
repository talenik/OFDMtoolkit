function dB = todB( M )

if ~isreal( M ) || any( M < 0 )
	warning('logarithm of a negative or complex matrix') ;
end
dB = 10 * log10( M ) ;
