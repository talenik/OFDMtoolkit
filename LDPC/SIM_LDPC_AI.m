clc ;
clear ; 
format compact ;
path( [ '..' filesep 'lab3' ], path ) ;

% Exercise 10.21 - actual waterfall curve simulation
%settings-------------------------------------------

%code params
N			= 648 ;	 % valid : [ 648, 1296, 1944 ]
R			= 1 / 2  % valid: [ 1/2 2/3 3/4 5/6 ]

%decoder params
nIter		= 8

%simulation params
EbNo		= [ 1 : 0.5 : 3 ]
BlockSize	= 1 ;
bMul		    =    20 ;
Nblocks		= bMul * [ 1 : 1 : size( EbNo, 2 ) ]

%end o settings-------------------------------------

nCodewords	= Nblocks * BlockSize ;
bits		= nCodewords * N ;			% number of bits processed

code		= loadWIFI6_LDPC( R, N ) 
K			= code.K ;
H			= LDPCExpandH( code.Hbm, code.z ) ;

ERR			= zeros( 2, size( EbNo, 2 ) ) ;		% absolute number of errors
BER			= zeros( 2, size( EbNo, 2 ) ) ;		% bit error ratio after LDPC decoding

for x = 1:1:size( EbNo, 2 )
	% BPSK transmitter -------------------------
	Dataword	= binarySource( K, BlockSize ) ;
	Codeword	= encodeLDPC( Dataword, H )' ;	% all zero codewords for now
	TxBlock		= -2 * Codeword + 1 ;					% BPSK modulated 0 -> +1
	
	% calculating AWGN channel parameters
	ebno	= EbNo( x ) ;
	snr     = 10 ^ ( ebno / 10 ) ;
	varCh	= 1 / ( 2 * snr * code.R ) ;	% account for coderate in noise variance
	sigma	= sqrt( varCh ) ;
	
	for t = 1 : 1 : Nblocks( x )
		
		Noise	= sigma * randn( size( TxBlock ) ) ;
		RxBlock	= TxBlock + Noise ;

        Zn0         = ( 2 / varCh ) * RxBlock ;
		
		HD				= decodeLDPC( H, Zn0, nIter ) ;
		HD_AI			= decodeLDPC_GPT( H, Zn0, nIter ) ;
		ERR( 1, x )		= ERR( 1, x ) + dHam( Codeword, HD ) ;
		ERR( 2, x )		= ERR( 2, x ) + dHam( Codeword, HD_AI ) ;
				
	end
	
	disp([ ' Eb/No: ' num2str( EbNo( x ) ) ', Errors: ' num2str( ERR( x ) ) ', Bits: ' num2str( bits( x ) ) ]) ;
end

%% postprocessing 

BER			= ERR ./ bits ;


S = 0.9
[ CI, err ]		= confidenceInterval( S, BER( 1, : ), bits ) ;
[ CI, err2 ]	= confidenceInterval( S, BER( 2, : ), bits ) ;

figure() ;
	set( gcf, 'color', 'w' ) ;
	set(gca, 'YScale', 'log') ;
	errorbar( EbNo, BER( 1, : ), err ) ;
	errorbar( EbNo, BER( 2, : ), err2 ) ;
	set(gca, 'YScale', 'log') ;
	xlabel('Eb/No [dB]') ;
	ylabel('BER') ;
	%semilogy( EbNo, [ BER ] ) ;
	grid on ;

EbNo
BER

