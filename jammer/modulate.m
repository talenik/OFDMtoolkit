function SSC = modulate( Bits, mod )
%function [ SSC ] = modulate( Bits, mod )
%	perform binary to signal space constellation mapping
%	using Gray mapping and normalizing to unit average power
%inputs:
%	Bits is a binary-valued matrix of parallel blocks - columns, preferred type: logical
%		nr. of rows must be divisible by mod.M
%	mod - modulation structure, required fields:
%		M		- modulation order (must be a power of two)
%		diff	- true/false - differential modulation
%				  Differential encoding is done column-wise per column
%				  Assuming zeroth bit is zero
%				  Symbol-wise aka working on blocks of k = log2(M) bits
%		type	- string further specifying type:
%		modulations implemented from scratch:
%			BPSK	- real valued BPSK 0 > +1, 1 > -1
%			CBPSK	- complex valued BPSK 0 > e(i*pi/4), 1 > -e(i*pi/4)
%			DBPSK	- differentially encoded real valued BPSK
%			DCBPSK	- differentially encoded complex valued BPSK
%			QPSK	- aka 4QAM complex valued Gray encoded
%			DQPSK	- aka 4QAM differentially encoded, complex valued Gray encoded 
%		modulations calling a qammod wrapper:
%			QAM		- QAM, depending by M
%			DQAM	- differentially encoded QAM
%outputs:
%	SSC	- Signal Space Constellation
%		  vector or matrix of real or complex numbere
%			real for BPSK, complex for all others

	[ y, x ]	= size( Bits ) ;
	k			= log2( mod.M ) ;
	if k ~= floor( k )
		error( 'modulation order not a power of 2, M: %d', mod.M ) ;
	end

	[ q, r ]	= divmod( y, k ) ;
	if( r ~= 0 )
		error( 'number of rows not divisible by bits per symbol' ) ;
	end
	
	if mod.M == 2	%BPSK, CBPSK, DBPSK, DCBPSK
		if mod.diff
			%implement differential encoding
			DBits	= difEnc( Bits ) ;
		else
			DBits	= Bits ;
		end
	
		SSC = BPSKmod( DBits ) ; %the only real-valued modulation
	
		if isequal( mod.type, 'CBPSK' )
			SSC = SSC * exp( i * pi/4 ) ; 
		end
	
	elseif strfind( mod.type, 'QPSK' ) %custom implementation: QPSK, DQPSK
		%reshape data to 3D volume
		T	 = reshape( Bits, k, q, x ) ;
		Bits = permute( T, [ 2 3 1 ] ) ; %inv perm [ 3 1 2 ]
		
		if mod.diff
			DBits = difEnc( Bits, k ) ;
		else
			DBits = Bits ;
		end
			
		%first plane > Y, second plane > X
		Re	= BPSKmod( DBits( :, :, 1 ) ) ;
		Im	= BPSKmod( DBits( :, :, 2 ) ) ;
		SSC = ( 1 / sqrt( 2 ) ) * ( Re + i * Im ); 
	
		assert( isequal( size( SSC ), [ q, x ] ) ) ;
	
	elseif strfind( mod.type, 'QAM' ) %qammod wrapper for higher order modulations

		if log2( mod.M ) ~= floor( log2( mod.M ) )
			error( 'unsupported modulation Order: %s', mod.M ) ;
		end

		if mod.diff
			DBits = difEnc( Bits, k ) ;
		else
			DBits = Bits ;
		end

		%Dbits is now a 2D matrix, not a 3D volume
		SSC = qammod( Bits, mod.M, InputType = 'bit', UnitAveragePower = true ) ;
	else
		error( [ 'unsupported modulation type: ' mod.type ] ) ;
	end

	%testing for unit average power
	checkPower( SSC, 1, 1e-2 ) ;
end

function C = BPSKmod( B )
	C = -2 * B + 1 ; %0 > +1, 1 > -1
end
