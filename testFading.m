%Notes from documentation:
% By convention, the first delay is set to zero.
% Indoor: path delays after the first between 1e-9 & 1e-7 s
% Outdoor: path delays after the first between 1e-7 & 1e-5 seconds
% 
% Chooose realistic channel values:
% https://www.mathworks.com/help/comm/ug/fading-channels.html#a1069863931b1
% 
% Average path gain:
% practice: large negative dB value
% simulation: in the range [-20, 0] dB.
% To ensure that the expected total power of the combined path gains is 1 use NormalizePathGains
% 
% Doppler shift: fd = v * fc / c
% A maximum Doppler shift of 0 corresponds to a static channel that comes from a Rayleigh or Rician distribution.
% 
% For Rician fading, the K-factor is typically in the range [1, 10]. (linear scale)
% A K-factor of 0 corresponds to Rayleigh fading.

%% Test 1: create Rayleigh channel object with three paths and show visualization
cl ;

RayCh = comm.RayleighChannel() ;
RayCh.SampleRate			= 100000 ;
RayCh.MaximumDopplerShift = 130 ;
RayCh.PathDelays			= [ 0,  1.5e-5, 3.2e-5 ] ;
RayCh.AveragePathGains	= [ 0,		-3,     -3 ] ;
RayCh.Visualization		= 'Impulse response' ;
RayCh

tx			= randi( [ 0 1 ], 500, 1 ) ;
dbspkMod	= comm.DBPSKModulator ;
dpskSig		= dbspkMod( tx ) ;
y			= RayCh( dpskSig ) ; %actual visualization

%% Test 2: Time fading of a constant signal
cl ;

RayCh = comm.RayleighChannel() ;
RayCh.SampleRate			= 100000 ;
RayCh.MaximumDopplerShift	= 100 ;	%defines time-change: larger  value > faster change 

sig = 1i * ones( 2000, 1 ) ; 
out = RayCh( sig ) ;

RayCh
plot( 20 * log10( abs( out ) ) )

%% TEST 3: frequency-flat Rayleigh fading channel object
% When applying channel impairments, the fading channel filter can be applied before the loop on SNR values. 
% Since the AWGN must account for the SNR, the signal is passed through the AWGN channel filter later,
cl ;

mod		= comm.DBPSKModulator ;
demod	= comm.DBPSKDemodulator ;
Rchan	= comm.RayleighChannel( SampleRate = 1e4, MaximumDopplerShift = 100 ) ;
awgnCh	= comm.AWGNChannel( NoiseMethod='Signal to noise ratio (SNR)' ) ;
errCalc = comm.ErrorRate ;

M	= 2 ;                       % DBPSK modulation order, must be 2 
tx	= randi( [0 M - 1 ], 50000, 1 ) ;

dpskSig		= mod( tx ) ;
fadedSig	= Rchan( dpskSig ) ;

%plot time variations of a frequency flat fading channel
sig			= [ dpskSig fadedSig ] ;
figure() ;
set(gcf, 'Position', [400, 300, 600, 600]); % [left, bottom, width, height]
subplot( 2, 1, 1 ) ;
plot( abs( sig( 1 : 100, : ) ) )
subplot( 2, 1, 2 ) ;
plot( real( sig( 1 : 100, : ) ) )

SNR		= 0 : 2 : 20 ;			%binary modulation: SNR == EbN0
numSNR	= length( SNR ) ;
berVec	= zeros( 3, numSNR ) ;

for n = 1 : numSNR
   awgnCh.SNR = SNR( n ) ;
   rxSig	= awgnCh( fadedSig ) ;
   rx		= demod( rxSig );
   reset( errCalc ) ;
  
   berVec( :, n ) = errCalc( tx, rx ) ;
end

BER = berVec( 1, : ) ;
% calculate theoretical BER curve for fading channel (binary modulation: SNR == EbN0):
BERtheory = berfading( SNR,'dpsk', M, 1 ) ;

figure() 
set(gcf, 'Position', [1060, 300, 600, 600]); % [left, bottom, width, height]
semilogy( SNR, BERtheory, 'b-', SNR, BER, 'r*' ) ;
legend('Theoretical BER','Empirical BER');
xlabel('SNR (dB)'); 
ylabel('BER');
title('Binary DPSK over Rayleigh Fading Channel') ;

%% TEST 4: plot BER curve for various fading channels and modulations
cl ;

divorder	= 1 ;			%diversity order
coherence	= 'coherent' ;	%also try noncoherent
rho			= 0 ;			%complex correlation coefficient for FSK
K			= 1 ;			%Rician K-factor
phaserr		= 0 ;			%standard deviation of carrier phase error
sps			= 1 ;			%samples per symbol
R			= 1 ;			%ECC coding rate

BPS		= [ 2 : 4 ] ;
LSP		= [ "b-*", "r-o", "g-+" ] ;	%Line Specifiers
SNR		= [ 0 : 2 : 20 ] ;
BERT	= zeros( length( SNR ), length ( BPS ) ) ; 
SERT	= zeros( size( BERT ) ) ;

%Rayleigh fading channel - no K factor:
figure() ;

for k = BPS
	M = 2 ^ k ; 			%bits per symbol

	%TODO check conversion for OFDM
	EbN0 = convertSNR( SNR,'snr', 'ebno', ...
		SamplesPerSymbol = sps, BitsPerSymbol = k, CodingRate = R ) ;
	[ BERT( :, k ), SERT( :, k ) ] = berfading( EbN0,'qam', M, divorder ) ;

	subplot( 1, 2, 1 ) ;
	semilogy( EbN0, BERT( :, k ), LSP( k - 1 ) ) ;
	hold on ;
	subplot( 1, 2, 2 ) ;
	semilogy( EbN0, SERT( :, k ), LSP( k - 1 ) ) ;
	hold on ;
end

grid on ;

%TODO Rician fading
% figure() ;
% 
% semilogy( EbN0, BERT( :,1 ),'b-*')
% (EbN0, BERT( :,2 ),'r-o'  ) ;
% title('4,8,16-QAM Rayleigh BER') ;
% grid on ;
% subplot( 1, 2, 2 ) ;
% semilogy( EbN0, SERT( :,1 ),'b-*', EbN0, SERT( :,2 ),'r-o'  ) ;
% title('4,8,16-QAM Rayleigh SER') ;
% grid on ;


%% TEST 5 - Channel filter delays
cl ;

bitRate = 50000 ;
mod		= comm.DBPSKModulator ;
demod	= comm.DBPSKDemodulator ;
RayCh	= comm.RayleighChannel( ) ;
RayCh.SampleRate			= bitRate ;
RayCh.MaximumDopplerShift	= 4 ; 
RayCh.PathDelays			= [ 0 0.5 / bitRate ] ;
RayCh.AveragePathGains		= [ 0 -10 ] ;

%show basic channel object parameters:
RayCh
%TODO: IMPORTANT: more detailed channel object parameters
chInfo	= info( RayCh )
chFIR	= chInfo.ChannelFilterCoefficients
delay	= chInfo.ChannelFilterDelay

errorCalc = comm.ErrorRate( ReceiveDelay = delay ) ;

M	= 2;                       % DBPSK modulation order
tx	= randi( [ 0 M - 1 ], 50000, 1 ) ;
dpskSig		= mod(tx);
fadedSig	= RayCh( dpskSig ) ;
rx			= demod( fadedSig ) ;

berVec = errorCalc( tx, rx ) ;
fprintf("%d bits received, %d bits in error, BER: %1.2f.\n", berVec( 3 ), berVec( 2 ), berVec( 1 ) ) ;

%TODO: try the convolution myself
%TODO: try BER calculation myself

%% TEST 6: Use fading channel in loop
cl ; 
%TODO: example seems to show much less distortion with the same settings
%openExample('comm/ChannelFilteringUsingForLoopExample')

bitRate		= 50000;	% Data rate is 50 kb/s
numTrials	= 125 ;		% Number of iterations of loop
M			= 4 ;		% QPSK modulation order
phaseoffset = pi / 4 

qpskMod = comm.QPSKModulator ;
RayCh	= comm.RayleighChannel() ;
RayCh.SampleRate			= bitRate ;
RayCh.MaximumDopplerShift	= 4 ;
RayCh.PathDelays			= [ 0 2e-5 ] ;
RayCh.AveragePathGains		= [ 0 -9 ] ;
Raych.NormalizePathGains	= true ;	
RayCh
chInfo	= info( RayCh )
cd		= comm.ConstellationDiagram

%pskmod([0 M-1],M,phaseoffset,PlotConstellation=true);

for n = 1 : numTrials
   tx		= randi( [0 M - 1 ], 500, 1 ) ;
   pskSig	= pskmod( tx, M, phaseoffset ) ;
   fadedSig = RayCh( pskSig ) ;
   
   % Plot the new data for each for loop iteration.
   update( cd, fadedSig ) ;
end

%% TEST 7

numBits		= 10000 ;	% Each frame 10000 bits long
numTrials	= 20 ;		% Number of frames simulated
M = 4 ;

dpskMod		= comm.DPSKModulator( ModulationOrder = M ) ;
dpskDemod	= comm.DPSKDemodulator( ModulationOrder = M ) ;
ricianChan	= comm.RicianChannel( KFactor = 3, MaximumDopplerShift = 0 ) ;

nErrors = zeros( 1, numTrials ) ;
bErrors = zeros( 1, numTrials ) ;

for n = 1 : numTrials
	tx			= randi( [0 M - 1 ], numBits, 1 ) ;
	dpskSig		= dpskMod( tx ) ;
	fadedSig	= ricianChan( dpskSig ) ;
	rxSig		= awgn( fadedSig, 14, 'measured' ) ;
	rx			= dpskDemod( rxSig ) ;

	%ignore 1st sample because differential modulation	
	tx = tx( 2 : end ) ;
	rx = rx( 2 : end ) ;
	nErrors( n ) = symerr( tx, rx ) ; %symbol err
	bErrors( n ) = biterr( tx, rx, log2( M ) ) ;
end
nErrors
bErrors
fer = mean( nErrors > 0 )

%% Exmple from Fading Channel documentation
c  = 3e+8	%lightspeed
fc = 2.4e+9	%Hz
Rm = 10e+6	%baud == sybmbols per second

v  = 1		% m/s pedestrian walk
fd = ( v * fc ) / c
T0 = 1 / ( 100 * fd )
nB = Rm * T0

v  = 20		% m/s car in the city
fd = ( v * fc ) / c
T0 = 1 / ( 100 * fd )
nB = Rm * T0



%% TEST 7: Quasi-static chanel model