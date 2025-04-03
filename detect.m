function Bits = detect( Zch, mod )
% function [ Bits ] = detect( Zch, mod )
%	detect/demodulate QAM modulation, see help modulate for details
%	assuming equalization already happened
%	expecting approximately unit average signal power
%inputs:
%	Zch is a column vector or matrix with columns processed independently 
%	mod - modulation structure, required fields:
%		M		- modulation order (must be a power of two)
%		diff	- true/false - differential modulation	
%output:
%	Bits - detected bits

	[ y, x ]	= size( Zch ) ;
	k			= log2( mod.M ) ;

	if k ~= floor( k )
		error( 'modulation order not a power of 2, M: %d', mod.M ) ;
	end

	if mod.M == 2
		%CBPSK rotate BACK by 45 degrees
		if isequal( mod.type, 'CBPSK' )
			Zch = Zch * exp(-i * pi / 4 ) ;
		end

		DBits = BPSKdem( Zch ) ;

		if mod.diff
			Bits = difDec( DBits ) ; %differential decoding	
		else
			Bits = DBits ;
		end

	elseif strfind( mod.type, 'QPSK' )
		assert( k == 2 ) ;
	
		DBits = zeros( y, x, k, 'logical' ) ;
		DBits( :, :, 1 ) = BPSKdem( real( Zch ) ) ;
		DBits( :, :, 2 ) = BPSKdem( imag( Zch ) ) ;
		
		%3D volume differential decoder	
		if mod.diff
			Bits = difDec( DBits, k ) ; %differential decoding	
		else
			Bits = DBits ;
		end
		
		%permute back to 2D matrix 
		T = permute( Bits, [ 3 1 2 ] ) ;
		Bits = reshape( T, k * y, x, 1 ) ; 

	elseif strfind( mod.type, 'QAM' )

		DBits = qamdemod( Zch, mod.M, OutputType = 'bit', UnitAveragePower = true ) ;

		%2D matrix differential decoder	
		if mod.diff
			Bits = difDec( DBits, k ) ;
		else
			Bits = DBits ;
		end
	else
		error( 'unsupported modulation type: %s',  mod.type ) ;
	end
end		

function B = BPSKdem( C )
	B = zeros( size( C ), 'logical' ) ;
	B( real( C ) < 0 ) = 1 ;
end
