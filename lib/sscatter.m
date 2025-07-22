function sscatter( M )
%fixing the horrible mess that is scatter and scatterplot
V = M(:) ;

if isreal( V )
	r = V ;
	i = zeros( size( V ) ) ;
else
	%complex valued
	r = real( V ) ;
	i = imag( V ) ;
end

figure() ;
scatter( r, i, 100, "filled", 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'k'  ) ;