format compact ;
path( "." + filesep + "lib", path ) ;
cl ;

%Tested OK for:
%	all forms BPSK, QPSK
%	QAM M = 4, 16
%Known bugs:
%	differential encoding with QAM - potentially incompatible symbol-bit mapping
%TODO:
%	rayleigh channel - quasi static
%		signal space - FDE perfect CSI in RX , zero forcing EQ
%		signal space - FDE estimated CSI in RX, MMSE EQ 
%		pulse shaping test - matrix frame
%		pulse shaping sim - vector frame with IBI
%		SS jammer - pilot jamming
%		SS jammer - AWGN jamming
%		SS jammer - CP attack

%Notes:
%qammod - cannot do differential encoding, but no biggie
%qamdemod can do fixed point, integer output, also soft output
%comm.PSKModulator & comm.PSKDemodulator, comm.QPSKModulator & comm.QPSKDemodulator to be replaced by pskmod and pskdemod


%% start of settings ------------------------------------------------------


path( '../', path )	;	%path for secret email config
path( 'lib', path ) ;

% simulation parameters

sim.EbN0	= [ 3 : 1 : 9 ] ;
sim.minErr	= 1000 ;				%TODO minimum nr. of errors for each Eb/N0 point, set 10000 for reliable results:
sim.maxBits = 1e8 ;					%max nr. of bit transfer simulated
sim.S		= 0.99 ;				%confidence level

sim.prof	= false ;				%profile code and show HTML report
sim.report	= false ;				%send email after each iteration is finished
sim.plot	= true ;				%plot waterfall figure in the end
sim.save	= false ;				%save results to local .mat file immediately in WTF
sim.debug	= false ;				%turn on debug output / verbosity level, if debug turned on ,just one simulation iteration is done
sim.type	= 1 ;					%simulation implementation type:
										%1 - custom
										%2 - toolbox packed bits (aka integer)
										%3 - toolbox non-packed bits (aka binary ) 
lightspeed = 3e+8 ;
%basic transmission parameters
mod.fc		= 2.5e+9 ;				%system carrier frequency
mod.Df		= 15e+3 ;				%delta f - subcarrier spacing
mod.type	= "BPSK"				%modulation: BPSK real/complex, 4QAM
if ismember( mod.type, [ "QAM", "DQAM" ] ) 
	mod.M	= 16 ;					%set custom modulation order
end

%basic derived parameters
mod.T		= 1 / mod.Df ;			%OFDM symbol time no CP
mod.lambda	= lightspeed / mod.fc ;		%system wavelength

if ~isempty( strfind( mod.type, 'D'))
	mod.diff	= true ;				%differential modulation 
else
	mod.diff	= false ;				
end

if ismember( mod.type , [ "BPSK", "DBPSK", "CBPSK", "DCBPSK" ] ) 
	mod.M	= 2 ;					%Nr. of constellation points
	mod.k	= 1 ;					%bits per symbol
elseif ismember( mod.type, [ "QPSK", "DQPSK" ] ) 
	mod.M	= 4 ;			
	mod.k	= 2 ;	
elseif ismember( mod.type, [ "QAM", "DQAM" ] ) 
	mod.k	= log2( mod.M ) ;
else
	error('unsupported modulation type') ;
end

%channel parameters - movement
chan.vel	= 20 ;						%relative RX/TX velocity in [ m/s ]
%derived channel parameters
if chan.vel > 0
	%TODO: various Doppler shift / fading rate formulas
	T0	= ( 0.5 * mod.lambda ) / chan.vel 		%coherence time Sklar
	fd	= 1 / ( 100 * T0 )						%MATLAB fading channel documentation
	%alternatively:
	%Quasi static Channel: a path gain in a fading channel changes insignificantly over a period of 1/(100fd) seconds
	fd	= mod.fc * ( chan.vel / lightspeed )
	T0	= 1 / ( 100 * fd )
else
	chan.T0 = inf ;
	chan.fd = 0 ;
end

%channel parameters - terrain
chan.sigtau	= 1e-6 ;					%RMS delay spread in seconds (Debbah: large open space 1000 ns)
chan.f0		= (1/5) * chan.sigtau ;		%coherence bandwidth (Sklar: fo(50%))

%OFDM paramters
mod.N		= 1024 ;							%Fourier transform size 
mod.Nc		= mod.N ;						%number of data-subcarriers (must be <= N)
mod.Ncp		= (1/4) * mod.N ;				%Cyclic Prefix size in samples
mod.ospf	= 192 ;							%nr. of OFDM symbols per frame

%derived OFDM parameters
mod.Nof		= mod.N + mod.Ncp ;				%samples per OFDM symbol with CP
mod.fs		= mod.N * mod.Df ;				%sampling frequency
mod.Ts		= 1 / mod.fs ;					%sampling time in seconds
mod.Tof		= mod.Nof * mod.Ts ;			%OFDM symbol time with CP
mod.Tcp		= mod.Ncp * mod.Ts ;			%OFDM CP duration, must be > channel excess delay 
mod.sps		= 1 ;							%TODO samples per symbol - TODO oversampling
mod.bpos	= mod.Nc * mod.k ;				%data bits per OFDM symbol
mod.bpf		= mod.bpos * mod.ospf ;			%data bits per frame


%ECC parameters TODO
cod.k		= mod.Nc ;					%data-word size
cod.R		= 1 ;						%code rate

sim
mod

fprintf("\nModulation: %s, Nc: %d, k: %d, OSpF: %d, BPF: %d \n", mod.type, mod.Nc, mod.k, mod.ospf, mod.bpf ) ;

% end of settings --------------------------------------------------------
% TODO sanity checks: coherence time and coherence badwidth, ...
assert( mod.Ts == mod.T / mod.N ) ;
assert( mod.Tcp > chan.sigtau ) ;		%TODO sigtau is RMS value, not maximum value
mod.Tof
mod.Tcp

chan.Rayleigh = comm.RayleighChannel ;
chan.Rayleigh.SampleRate			= mod.fs ;
chan.Rayleigh.PathDelays			= [ 0 1e-5 ] ;	%TODO two paths for now
chan.Rayleigh.AveragePathGains		= [ 0 -10 ] ;	%in dB
chan.Rayleigh.NormalizePathGains	= 1 ;
%chan.Rayleigh.MaximumDopplerShift	= chan.fd ;		%TODO
%chan.Rayleigh.DopplerSpectrum		= doppler( 'Jakes' ) ;
chan.Rayleigh.RandomStream			= 'mt19937ar with seed' ;
chan.Rayleigh.Seed					= 2571 ;
chan.Rayleigh.Visualization			= 'Impulse and frequency responses' ;

%TWO options of implementing fading:
%TODO: let the channel object filter the signal itself:
chan.Rayleigh.ChannelFiltering		= 1 ;		
chan.Rayleigh.PathGainsOutputPort	= 1 ;
%TODO: let the channel object output the channel path gains and do the convolution myself
% chan.Rayleigh.ChannelFiltering	= 0 ;		
% chan.Rayleigh.PathGainsOutputPort	= 1 ;
% chan.Rayleigh.NumSamples			= mod.ospf * mod.Nof ;

fc = 1 ; %cutoff frequency factor depends on Doppler spectrum type Jakes => 1, see help
assert( chan.Rayleigh.MaximumDopplerShift < mod.fs / ( 10 / fc ) ) ; %TODO

%usage: [ TXdis, pathgains ] = chan.Rayleigh( TX ) ;

cho = chan.Rayleigh
chi = info( cho )

%% main simulation loop

s			= size( sim.EbN0 ) ;
sim.ERR		= zeros( s ) ;		% absolute nr. of errors 
sim.DBits	= zeros( s ) ;		% number of data bits simulated
sim.Frames	= zeros( s ) ;		% number of frames simulated
sim.BER		= zeros( s ) ;		% bit error ratio
sim.SNR		= zeros( s ) ;		% converted EbN0 > SNR valued in dB

fprintf("\n MODULATION: %s, diff encoding: %d\n\n", mod.type, mod.diff ) ;
	
for x = 1 : length( sim.EbN0 )
	EbN0		= sim.EbN0( x ) ;
	chan.snr	= convertSNR( EbN0, 'ebno', BitsPerSymbol = mod.k, CodingRate = cod.R, SamplesPerSymbol = mod.sps ) ;

	nErr		= 0 ;
	nFrames		= 0 ;
	nBits		= 0 ;

	while nErr < sim.minErr && nBits < sim.maxBits

		TXDATA			= randi( [ 0 1 ], mod.bpos, mod.ospf ) ;		%matrix nr.carriers x OFDM symbols
		
		TXSS			= modulate( TXDATA, mod ) ;
		checkPower( TXSS, 1, 1e-2 ) ;

		TXFREQ			= TXSS ;										%TODO carrier and guard allocation
		TXTIME			= sqrt( mod.N ) * ifft( TXFREQ ) ;				%IDFT
		TXOFDM			= [ TXTIME( mod.N - mod.Ncp + 1 : end, : ) ; TXTIME ] ;	%cyclic prefix insertion
		%TXVEC			= TXOFDM( : ) ;									%single long vector of samples

		[ RXSS, vNss, NOISESS ]		= AWGNChan( TXSS, chan.snr, mod, cod ) ;
		[ RXOFDM,vNof, NOISEOF ]	= AWGNChan( TXOFDM, chan.snr, mod ) ;

		RXTIME			= RXOFDM( mod.Ncp + 1 : end, : ) ;				%cyclic prefix removal
		RXFREQ			= ( 1 / sqrt( mod.N ) ) * fft( RXTIME ) ;		%DFT

		RXSS			= RXFREQ ;										%TODO: implement FDE

		RXDATA			= detect( RXSS, mod ) ;

		nErr			= nErr + nnz( logical( TXDATA ) ~= logical( RXDATA ) ) ;
		nFrames			= nFrames + 1 ;
		nBits			= nBits + mod.bpf ;
	
		assert( prod( size( TXDATA ) ) == mod.bpf ) ;
		assert( size( TXFREQ, 1 ) == mod.N ) ;
		assert( size( TXTIME, 1 ) == mod.N ) ;
		assert( size( TXOFDM, 1 ) == mod.Nof ) ;
		assert( size( RXOFDM, 1 ) == mod.Nof ) ;
		assert( size( RXTIME, 1 ) == mod.N ) ;
		assert( size( RXFREQ, 1 ) == mod.N ) ;		

		if sim.debug
			whos
			% figure() ; 
			% subplot( 2, 2, 1 )  ; scatter( real( TXSS ), imag( TXSS ), 30 ) ;
			% subplot( 2, 2, 2 )  ; scatter( real( NOISE ), imag( NOISE ), 2 ) ;
			% subplot( 2, 2, 3 )  ; scatter( real( RXSS ), imag( RXSS ), 2 ) ;
			% assert( valueOK( NOISE ) ) ;	%sanity check - no NaN or Inf values
			% assert( isBinary( TXDATA ) ) ;
			% assert( equals( mean( NOISE , 'all' ), 0, 1e-2 ) ) ;
			% assert( equals( var( NOISE , 0, 'all' ), vn, 1e-1 ) ) ;
			% assert( equals( abs( TXSS ), ones( size( TXSS ) ), 1e-6 ) ) ; %test unit signal energy
			% assert( isBinary( RXDATA ) ) ;
			break ;
		end
	end

	sim.ERR( x )	= sim.ERR( x ) + nErr ;
	sim.DBits( x )	= sim.DBits( x ) + nBits ;
	sim.Frames( x )	= sim.Frames( x ) + nFrames ;
	sim.BER( x )	= sim.ERR( x ) / sim.DBits( x ) ;
	sim.SNR( x )	= chan.snr ;
	fprintf('EbN0: %d dB, SNR: %4.2f dB, Nss: %4.2f, Nof: %4.2f, nErr: %d, nBits: %d, BER: %e \n', EbN0, chan.snr, vNss, vNof, nErr, nBits, sim.BER( x ) ) ;
	if sim.debug
		break ;
	end
end

%% postprocessing --------------------------------------------------------
[ CI, err ] = confidenceInterval( sim.S, sim.BER, sim.DBits ) ;

if ~sim.debug
	if sim.plot
		figure() ;
		% subplot( 1, 2, 1 ) ;
		% semilogy( sim.EbN0, sim.BER ) ;
		% grid on ;
		% subplot( 1, 2, 2 ) ;
		set( gcf, 'color', 'w' ) ;
		errorbar( sim.EbN0, sim.BER, err ) ;
		grid on ;
		set(gca, 'YScale', 'log') 
		xlabel('Eb/No [dB]') ;
		ylabel('BER') ;
		title( mod.type + " differential: " + mod.diff + " minimum err: " + sim.minErr ) ;
		grid on ;
	end
end

EBN0	= sim.EbN0
FRAMES	= sim.Frames
DBits	= sim.DBits
ERR		= sim.ERR
BER		= sim.BER
SNR		= sim.SNR


