function [ CI, err ] = confidenceInterval( S, BER, bits )
%function [ CI, err ] = confidenceInterval( S, BER, bits )
%	calculates confidence intervals for BER curve
%	see TODO PAPER for details
%	results go straight to errorbars
	l = length( BER ) ;
	if l ~=  length( bits )
		error('input size mismatch') ;
	end
	CI	= zeros( 2, l ) ;
	err = zeros( 1, l ) ;

	for i = 1 : l
		p	= BER( i ) ;
		r	= bits( i ) ;

		A	= accuracy( p, r ) ;
		k	= confIfraction( A, S ) ;
		T	= p * [ 1 - k, 1 + k ]' ; 

		CI( :, i )	= T ;
		err( i )	= p * k ; 
	end
end

function k = confIfraction( A, S )
	k = sqrt( 2 / A ) * erfinv( S ) ;
end

function A = accuracy( p, r )
	A = p * r / ( 1 - p ) ;
end