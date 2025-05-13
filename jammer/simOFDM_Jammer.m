clear ;
clc ;
format compact ;


%% start of settings ------------------------------------------------------


path( '../', path )	;	%path for secret email config
path( 'lib', path ) ;

% simulation parameters

sim.EbN0	= [ 3 : 1 : 18 ] ;
sim.minErr	= 1000 ;				%TODO minimum nr. of errors for each Eb/N0 point, set 10000 for reliable results:
sim.maxBits = 1e10 ;					%max nr. of bit transfer simulated
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
lightspeed	= 3e+8 ;
%basic transmission parameters
mod.fc		= 2.5e+9 ;				%system carrier frequency
mod.Df		= 15e+3 ;				%delta f - subcarrier spacing
mod.type	= "QPSK"				%modulation: BPSK real/complex, 4QAM
if ismember( mod.type, [ "QAM", "DQAM" ] ) 
	mod.M	= 16 ;					%set custom modulation order
end

%basic derived parameters
mod.T		= 1 / mod.Df ;			%OFDM symbol time no CP
mod.lambda	= lightspeed / mod.fc ;	%system wavelength

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
chan.vel	= 0 ;						%relative RX/TX velocity in [ m/s ]
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

%channel jamming parameters
chan.SJRF	= 20 ;						%singal to Jammer ratio in [dB]
chan.SJRP	= 50 ;						%singal to Jammer ratio in [dB]

%OFDM paramters
mod.N		= 1024 ;						%Fourier transform size 
mod.Nc		= mod.N ;						%number of data-subcarriers (must be <= N)
mod.Ncp		= (1/4) * mod.N ;				%Cyclic Prefix size in samples
mod.ospf	= 192 ;							%nr. of OFDM symbols per frame
mod.pilotSp = 10 ;                          %pilot spacing (in subcarriers)

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

%multipath channel parameters:
chan.paths		= 3
chan.PathDelays = 10 * mod.Ts * [ 0 1 2 ]  ;		%in tens of samples
chan.Pathgains	= [ 0 -5 -10 ] ;					%in dB
chan.Tmax		= 10 * ( chan.paths - 1 ) * mod.Ts 

sim
mod

fprintf("\nModulation: %s, Nc: %d, k: %d, OSpF: %d, BPF: %d \n", mod.type, mod.Nc, mod.k, mod.ospf, mod.bpf ) ;
fprintf("Sampling rate: %g [Hz] Ts: %g [s], Max path delay: %g [s]\n", mod.fs, mod.Ts, chan.Tmax ) ;

% end of settings --------------------------------------------------------
% TODO sanity checks: coherence time and coherence badwidth, ...

assert( mod.Ts == mod.T / mod.N ) ;
assert( mod.Tcp > chan.sigtau ) ;		%TODO sigtau is RMS value, not maximum value
mod.Tof
mod.Tcp

chan.Rayleigh = comm.RayleighChannel ;
chan.Rayleigh.SampleRate			= mod.fs ;
chan.Rayleigh.PathDelays			= chan.PathDelays ;
chan.Rayleigh.AveragePathGains		= chan.Pathgains ;	
chan.Rayleigh.NormalizePathGains	= 1 ;
chan.Rayleigh.MaximumDopplerShift	= chan.fd ;		%TODO
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
% cho( [ 1 ; zeros( ceil( cho.PathDelays( end ) / mod.Ts ) * 2, 1 ) ] ) ;
% cho.Visualization = 'Off' ;

chi = info( cho )

fprintf("\n MODULATION: %s, diff encoding: %d\n\n", mod.type, mod.diff ) 

%% main simulation loop

s			= size( sim.EbN0 ) ;
sim.ERR		= zeros( s ) ;		% absolute nr. of errors 
sim.ERRJ	= zeros( s ) ;		% absolute nr. of errors for a jammed transmission
sim.ERRJP	= zeros( s ) ;		% absolute nr. of errors for a jammed pilots
sim.DBits	= zeros( s ) ;		% number of data bits simulated
sim.Frames	= zeros( s ) ;		% number of frames simulated
sim.BER		= zeros( s ) ;		% bit error ratio
sim.BERJ	= zeros( s ) ;		% bit error ratio for jammed all
sim.BERJP	= zeros( s ) ;		% bit error ratio for jammed pilots
sim.SNR		= zeros( s ) ;		% converted EbN0 > SNR valued in dB

	
for x = 1 : length( sim.EbN0 )
	EbN0		= sim.EbN0( x ) ;
	chan.snr	= convertSNR( EbN0, 'ebno', BitsPerSymbol = mod.k, CodingRate = cod.R, SamplesPerSymbol = mod.sps ) ;

	nErr		= 0 ;
	nErrJ		= 0 ;
	nErrJP		= 0 ;
	nFrames		= 0 ;
	nBits		= 0 ;

	while nErr < sim.minErr && nBits < sim.maxBits

		TXDATA			= randi( [ 0 1 ], mod.bpos, mod.ospf ) ;		%matrix nr.carriers x OFDM symbols
		
		TXSS			= modulate( TXDATA, mod ) ;
		checkPower( TXSS, 1, 1e-2 ) ;
		S1 = sigPower( TXSS, 'all' ) ;

		TXFREQ			= TXSS ;										%TODO carrier and guard allocation
		TXTIME			= sqrt( mod.N ) * ifft( TXFREQ ) ;				%IDFT
		TXOFDM			= [ TXTIME( mod.N - mod.Ncp + 1 : end, : ) ; TXTIME ] ;	%cyclic prefix insertion
		%TXVEC			= TXOFDM( : ) ;									%single long vector of samples

		%channel with multipath and noise----------------------------------
		[ Ht, Tm ]	= impulseResponseFromChannel( chan.Rayleigh, mod.Ts ) ;
		Hf			= ( 1 / sqrt( mod.N ) ) * fft( Ht, mod.N, 1 ) ;         %channel frequency response
		TXISI		= filter( Ht, 1, [ TXOFDM ; zeros( Tm - 1 , mod.ospf ) ], [], 1 ) ;

		assert( Tm < mod.Ncp ) ;
		[ RXISI,vNof, NOISEISI ]	= AWGNChan( TXISI, chan.snr, mod ) ;

        %perfect CSI - unrealistic equalization
		EQP			= repmat( 1 ./ Hf, 1, mod.ospf ) ;
        %realistic equalization - pilot-based with interpolation
        HkI         = [ [ 1 : mod.pilotSp : mod.N ] mod.N ] ;
        RXHk		= interp1( HkI, Hf( HkI ), [ 1 : mod.N ] ).' ;
		de			= difff( Hf, RXHk ) ;
		EQk			= 1 ./ RXHk ;
		EQR			= repmat( EQk, 1, mod.ospf ) ;

		%all subcarriers jamming
		[ SdB, S ]		= sigPower( TXSS, 'all' ) ;

		JamF			= randnc( mod.N, mod.ospf, SdB - chan.SJRF ) ;
		JPF				= sigPower( JamF, 'all' ) ;
		%EQkJ			= EQk + JamF ;
		
		%[ EQkJ, JPF ]	= awgn( EQk, chan.SJR, 'measured' ) ;
		EQkJ			= repmat( EQk , 1, mod.ospf ) ;

		%pilot jamming
		Pilots			= Hf( HkI ) ;
		JamP			= randnc( size( Pilots, 1 ), 1, SdB - chan.SJRP ) ;
		JPP				= sigPower( JamP ) ;
		PilotsJ			= Pilots + JamP ;
		%[ PilotsJ, JPP]	= awgn( Pilots, chan.SJR, 'measured' ) ;
		RXHkJP			= interp1( HkI, PilotsJ, [ 1: mod.N ] ).' ;
		EQkJP			= 1 ./ RXHkJP ;
		EQkJP			= repmat( EQkJP, 1, mod.ospf ) ;

		%fprintf("Signal power1: %g 2: %g, Jammer power: full %g, pilots: %g\n", S1, SdB, JPF, JPP ) ;

		RXTIME			= RXISI( mod.Ncp + 1 : mod.Ncp + mod.N, : ) ;	%cyclic prefix removal
		RXFREQ			= ( 1 / sqrt( mod.N ) ) * fft( RXTIME ) ;		%DFT
		
		RXSSP			= EQP .* RXFREQ ;			%perfect EQ
		RXSS			= EQR .* RXFREQ ;			%interpolated EQ
		
		RXTIMEJ			= RXTIME + JamF ;			%jamm all samples
		RXFREQJ			= ( 1 / sqrt( mod.N ) ) * fft( RXTIMEJ ) ;
		RXSSJ			= EQk .* RXFREQJ ;			%jammed all subcarriers

		RXSSJP			= EQkJP .* RXFREQ ;			%jammed pilots-only

		RXDATA			= detect( RXSS, mod ) ;
		RXDATAJ			= detect( RXSSJ, mod ) ;
		RXDATAJP		= detect( RXSSJP, mod ) ;

		nErr			= nErr + nnz( logical( TXDATA ) ~= logical( RXDATA ) ) ;
		nErrJ			= nErrJ + nnz( logical( TXDATA ) ~= logical( RXDATAJ ) ) ;
		nErrJP			= nErrJP + nnz( logical( TXDATA ) ~= logical( RXDATAJP ) ) ;

		nFrames			= nFrames + 1 ;
		nBits			= nBits + mod.bpf ;
	
		assert( prod( size( TXDATA ) ) == mod.bpf ) ;
		assert( size( TXFREQ, 1 ) == mod.N ) ;
		assert( size( TXTIME, 1 ) == mod.N ) ;
		assert( size( TXOFDM, 1 ) == mod.Nof ) ;
		%assert( size( RXOFDM, 1 ) == mod.Nof ) ;
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
	sim.ERRJ( x )	= sim.ERRJ( x ) + nErrJ ;
	sim.ERRJP( x )	= sim.ERRJP( x ) + nErrJP ;

	sim.DBits( x )	= sim.DBits( x ) + nBits ;
	sim.Frames( x )	= sim.Frames( x ) + nFrames ;
	sim.BER( x )	= sim.ERR( x ) / sim.DBits( x ) ;
	sim.BERJ( x )	= sim.ERRJ( x ) / sim.DBits( x ) ;
	sim.BERJP( x )	= sim.ERRJP( x ) / sim.DBits( x ) ;
	sim.SNR( x )	= chan.snr ;
	fprintf('EbN0: %d dB, SNR: %4.2f dB, Nof: %4.2f, nErr: %d, nBits: %d, BER: %e \n', ...
		EbN0, chan.snr, vNof, nErr, nBits, sim.BER( x ) ) ;
	if sim.debug
		break ;
	end
end

% postprocessing --------------------------------------------------------
[ CI, err ]		= confidenceInterval( sim.S, sim.BER, sim.DBits ) ;
[ CIJ, errj ]	= confidenceInterval( sim.S, sim.BERJ, sim.DBits ) ;
[ CIJP, errjp ] = confidenceInterval( sim.S, sim.BERJP, sim.DBits ) ;

if ~sim.debug
	if sim.plot
		figure() ;
		% subplot( 1, 2, 1 ) ;
		% semilogy( sim.EbN0, sim.BER ) ;
		% grid on ;
		% subplot( 1, 2, 2 ) ;
		hold on ;
		set( gcf, 'color', 'w' ) ;
		errorbar( sim.EbN0, sim.BER, err ) ;
		errorbar( sim.EbN0, sim.BERJ, errj ) ;
		errorbar( sim.EbN0, sim.BERJP, errjp ) ;
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
ERRJ	= sim.ERRJ 
ERRJP	= sim.ERRJP 
BER		= sim.BER
BERJ	= sim.BERJ
BERJP	= sim.BERJP
SNR		= sim.SNR


