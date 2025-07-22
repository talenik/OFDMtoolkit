function Vn = normalize( V )
%assuming V is a complex- or real- valued vector

[ r, c ] = size( V ) ;
	if r > 1 && c > 1
		error( 'vector argument expected') ;
	end
	if r > 1
		E	= V' * V ;
	else
		E	= V * V' ; 
	end
	assert( isscalar( E ) && isreal( E ) ) ;

	Vn = V .* ( 1 / sqrt( E ) ) ;
end
