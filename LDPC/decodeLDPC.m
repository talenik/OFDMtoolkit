function Xne = decodeLDPC( H, Zn0, nIter )

[ M, N ] = size( H ) ;

ZMN = zeros( M, N ) ;
LMN = zeros( M, N ) ;

% Exercise 10.20a - Zmn buffer initialization
for m = 1 : M
	Nm	= ( H( m, : ) == 1 ) ;	%indices N(m) - using logical indices
	ZMN( m, Nm ) = Zn0( Nm ) ;		
end

NH = logical( ~H ) ;

for k = 1 : nIter

	% run horizontal scan sequentially for each row
	for m = 1 : M
		% Exercise 10.20b - find linear indices N(m) for row m
		Nm	= find( H( m, : ) == 1 ) ;		
		LMN( m, : ) = horizontal( N, Nm, ZMN( m, : ) ) ;
	end
	

	% Exercise 10.20d - update Zn(k) values eq. ( 10.43 )
	Znk = Zn0 + sum( LMN ) ;
	

	% Exercise 10.20e - update Zmn(k) values eq. ( 10.45 ) 
	for m = 1 : M
		ZMN( m, : ) = Znk - LMN( m, : )  ;		
	end
	ZMN( NH ) = 0 ;
	
	Xne = hardDecision( Znk ) ;


	% Exercise 10.20f - test orthogonality and return 
	if all( mod( H * Xne', 2 ) == 0 )
		return ;
	end
	
end

	disp('Decoding didnt converge successfully.') ;
end

function Lmn = horizontal( N, Nm, Zmn )

	Lmn = zeros( 1, N ) ;
	
	for n = Nm

		Nma		= Nm( Nm ~= n ) ;
		Zmna	= Zmn( Nma ) ;
		s		= prod( sign( Zmna ) ) ;
		m		= min( abs( Zmna ) ) ;
		
		Lmn( n ) = s * m ;	
		
	end
end

	
	