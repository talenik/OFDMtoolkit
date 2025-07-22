%% Notes

format compact ;
path( '../', path )	;	%path for secret email config
path( 'lib', path ) ;
path( 'MEX', path ) ;
cl ;

%% start of settings ------------------------------------------------------

%% simulation parameters


sim.minErr	= 1000 ;				%TODO minimum nr. of errors for each Eb/N0 point, set 10000 for reliable results:
sim.maxBits = 1e9 ;					%max nr. of bit transfer simulated
sim.S		= 0.99 ;				%confidence level

sim.prof	= false ;				%profile code and show HTML report
sim.report	= false ;				%send email after each iteration is finished
sim.plot	= true ;				%plot waterfall figure in the end
sim.save	= false ;				%save results to local .mat file immediately in WTF
sim.debug	= false ;				%turn on debug output / verbosity level, if debug turned on ,just one simulation iteration is done

% sim.ECC		= false ;				%turn ECC ON/OFF
% sim.EbN0	= [ 10 : 2 : 20 ] ;		%good values if ECC disabled
sim.ECC		= true ;
sim.EbN0	= [[ 0 : 1 : 6 ]] ;		%good values if ECC enabled
%sim.EbN0	= [ 4 : 1 : 6 ] ;	

sim.noise	= true ;				%debug purpose: disable noise, just distortion
sim.type	= 1 ;					%simulation implementation type:
										%1 - custom
										%2 - toolbox packed bits (aka integer)
										%3 - toolbox non-packed bits (aka binary ) 
sim.lightspeed	= 3e+8 ;
sim

%% basic transmission parameters
mod.fc		= 2.5e+9 ;				%system carrier frequency
mod.Df		= 15e+3 ;				%delta f - subcarrier spacing
mod.type	= "BPSK"				%modulation: BPSK real/complex, 4QAM
if ismember( mod.type, [ "QAM", "DQAM" ] ) 
	mod.M	= 16 ;					%set custom modulation order
end

%basic derived parameters
mod.T		= 1 / mod.Df ;				%OFDM symbol time no CP
mod.lambda	= sim.lightspeed / mod.fc ;	%system wavelength

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

mod

%% channel parameters 

% movement
chan.vel	= 0 ;						%relative RX/TX velocity in [ m/s ]
%derived channel parameters
if chan.vel > 0
	%TODO: various Doppler shift / fading rate formulas
	% T0	= ( 0.5 * mod.lambda ) / chan.vel 		%coherence time Sklar
	% fd	= 1 / ( 100 * T0 )						%MATLAB fading channel documentation
	
	%alternatively from MATLAB documentation:
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

% multipath channel parameters - independent from system :
chan.paths		= 3 ;
chan.PathDelays = round( pi, 2 ) * [ 0 1 2 ] * 1e-7 ;	%independent from sampling
chan.Pathgains	= [ 0 -5 -10 ] ;						%in dB

chan

%% ECC parameters

ECCN	= 1944 ;
Rc		= 1 / 2 ;
if sim.ECC
	%ECC parameters: cod.N, cod.R, cod.K	
	cod	= loadQCLDPC( 'wifi', Rc, ECCN ) ;
else
	cod.N	= ECCN ;
	cod.Rc	= 1 ;
	cod.K	= cod.N ;
end

enc = QCLDPCEncode() ; 		
dec = QCLDPCDecode() ;

dec.nIter	= 20 ;
dec.nthread = 16 ;
dec.build	= 'release' ;
dec.dbglev	= 1 ;
dec.method  = 'float' ;

cod
enc
dec

%% OFDM paramters

%TODO real system - Nc is less than N for guard interval, FFT size power of 2
%mod.N		= 1024 ;						%Fourier transform size 
%mod.Nc		= 1000 ;						%number of data-subcarriers (must be <= N)
%simulation - OFDM symbol size taylored to codeword size, FFT size not power of 2 
mod.Nc		= cod.N / mod.k ;				
mod.N		= mod.Nc ;
mod.cpf		= 1 / 16 ;						%fraction of OFDM symbol samples for cyclic prefix
mod.Ncp		= ceil( mod.cpf * mod.N ) ;		%Cyclic Prefix size in samples
mod.Ncp		= 20 ;
mod.ospf	= 192 ;							%nr. of OFDM symbols per frame

%derived OFDM parameters
mod.Nof		= mod.N + mod.Ncp ;				%samples per OFDM symbol with CP
mod.fs		= mod.N * mod.Df ;				%sampling frequency
mod.Ts		= 1 / mod.fs ;					%sampling time in seconds
mod.Tof		= mod.Nof * mod.Ts ;			%OFDM symbol time with CP
mod.Tcp		= mod.Ncp * mod.Ts ;			%OFDM CP duration, must be > channel excess delay 
mod.sps		= 1 ;							%TODO samples per symbol - TODO oversampling
mod.bpos	= mod.Nc * mod.k ;				%ENCODED binits per OFDM symbol
mod.dbpos	= mod.bpos * cod.Rc ;			%DATA bits per OFDM symbol
mod.bpf		= mod.bpos * mod.ospf ;			%ENCODED binits per frame
mod.dbpf	= mod.bpf * cod.Rc ;			%DATA bits per frame


chan.Tmax		= ceil( chan.PathDelays / mod.Ts ) ;	%max excess delay in samples

mod

fprintf("\nModulation: %s, Nc: %d, k: %d, OSpF: %d, BPF: %d \n", mod.type, mod.Nc, mod.k, mod.ospf, mod.bpf ) ;
fprintf("Sampling rate: %g [Hz] Ts: %g [s], Max path delay: %g [s]\n", mod.fs, mod.Ts, chan.Tmax ) ;

%% end of settings --------------------------------------------------------
% TODO sanity checks: coherence time and coherence badwidth, ...
assert( isInt( mod.Ncp ) ) ;
assert( mod.Ts == mod.T / mod.N ) ;
assert( mod.Nc <= mod.N ) ;

chan.Rayleigh						= comm.RayleighChannel ;
chan.Rayleigh.SampleRate			= mod.fs ;
chan.Rayleigh.PathDelays			= chan.PathDelays ;
chan.Rayleigh.AveragePathGains		= chan.Pathgains ;	
chan.Rayleigh.NormalizePathGains	= 1 ;
chan.Rayleigh.MaximumDopplerShift	= chan.fd ;		%TODO
%chan.Rayleigh.DopplerSpectrum		= doppler( 'Jakes' ) ;
chan.Rayleigh.RandomStream			= 'mt19937ar with seed' ;
chan.Rayleigh.Seed					= 2571 ;
%chan.Rayleigh.Visualization			= 'Impulse and frequency responses' ;
chan.Rayleigh.Visualization			= "Off" ;

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

[ Ht, Tm ]	= impulseResponseFromChannel( chan.Rayleigh, mod.Ts ) ;

if mod.Ncp < Tm
	warning('Prefix smaller than Tmax' ) ;
end


%% main simulation loop

s			= size( sim.EbN0 ) ;
sim.ERR		= zeros( s ) ;		% absolute nr. of errors uncoded
sim.ERRECC	= zeros( s ) ;		% absolute nr. of errors including ECC parity bits
sim.CBits	= zeros( s ) ;		% number of code bits simulated
sim.DBits	= zeros( s ) ;		% number of data bits simulated
sim.Frames	= zeros( s ) ;		% number of frames simulated
sim.BER		= zeros( s ) ;		% bit error ratio uncoded
sim.BERECC	= zeros( s ) ;		% bit eror ration after ECC decoding
sim.SNR		= zeros( s ) ;		% converted EbN0 > SNR valued in dB
sim.AIT		= zeros( s ) ;		% average nr. of iterations of LDPC decoder

sim.maxFrames = ceil( sim.maxBits / mod.bpf )

fprintf("\n MODULATION: %s, M:%d, diff encoding: %d\n\n", mod.type, mod.M, mod.diff ) ;
	
ITER = zeros( sim.maxFrames, mod.ospf ) ;

for x = 1 : length( sim.EbN0 )
	EbN0		= sim.EbN0( x ) ;
	chan.snr	= convertSNR( EbN0, 'ebno', BitsPerSymbol = mod.k, CodingRate = cod.Rc, SamplesPerSymbol = mod.sps ) ;

	nErr		= 0 ;
	nErrECC		= 0 ;
	nFrames		= 0 ;
	nBits		= 0 ;
	nBitsECC	= 0 ;
	nIter		= 0 ;

	while nErrECC < sim.minErr && nFrames < sim.maxFrames
		TXDATA			= randi( [ 0 1 ], cod.K, mod.ospf, 'uint8' ) ; %matrix nr.carriers x OFDM symbols
		if sim.ECC
			TXENCODED	= double( QCLDPCEncode( TXDATA, cod, enc ) ) ;
		else
			TXENCODED	= double( TXDATA ) ;
		end
		TXSS			= modulate( TXENCODED, mod ) ;
		checkPower( TXSS, 1, 1e-2 ) ;

		TXFREQ			= TXSS ;										%TODO carrier and guard allocation
		TXTIME			= sqrt( mod.N ) * ifft( TXFREQ ) ;				%IDFT
		TXOFDM			= [ TXTIME( mod.N - mod.Ncp + 1 : end, : ) ; TXTIME ] ;	%cyclic prefix insertion
		%TXVEC			= TXOFDM( : ) ;									%single long vector of samples

		%channel with multipath and noise----------------------------------
		%[ Ht, Tm ]	= impulseResponseFromChannel( chan.Rayleigh, mod.Ts ) ;
		Hf			= fft( Ht, mod.N, 1 ) ;         %channel frequency response
		TXISI		= filter( Ht, 1, [ TXOFDM ; zeros( Tm - 1 , mod.ospf ) ], [], 1 ) ;
		EQ			= repmat( 1 ./ Hf, 1, mod.ospf ) ;
		%whos ht Hf TXOFDM TXISI EQ
		
		if sim.noise
			[ RXISI,vNof, NOISEISI ]	= AWGNChan( TXISI, chan.snr, mod ) ;
		else
			%debug only
			RXISI		= TXISI ;
			vNof		= 0 ;
			NOISEISI	= zeros( size( TXISI ) ) ; 
		end
		%[ RXSS, vNss, NOISESS ]		= AWGNChan( TXSS, chan.snr, mod, cod ) ;
		%[ RXOFDM,vNof, NOISEOF ]	= AWGNChan( TXOFDM, chan.snr, mod ) ;

		%RXTIME			= RXOFDM( mod.Ncp + 1 : end, : ) ;				%cyclic prefix removal
		RXTIME			= RXISI( mod.Ncp + 1 : mod.Ncp + mod.N, : ) ;
		RXFREQ			= ( 1 / sqrt( mod.N ) ) * fft( RXTIME ) ;		%DFT
		%whos RXTIME RXFREQ EQ

		RXSS			= EQ .* RXFREQ ;										%TODO: implement FDE
		
		if sim.ECC
			RXLLR			= single( ( 2 / vNof ) .* RXSS ) ;
			LLR				= real( RXLLR ) ; %TODO - fix this hack :)
			[ ApLLR, Iter ] = QCLDPCDecode( LLR, dec ) ;
			RXDECODED		= hardDecision( ApLLR, enc.type ) ;
			RXDATA			= hardDecision( LLR( 1 : cod.K, 1 ), enc.type ) ;	%uncoded
		else
			RXDETECTED		= detect( RXSS, mod ) ;
			RXDECODED		= RXDETECTED ;
			RXDATA			= RXDECODED( 1 : cod.K, : ) ;
			Iter			= 0 ;
		end
				
		nErr			= nErr + nnz( logical( TXDATA ) ~= logical( RXDATA ) ) ;
		nErrECC			= nErrECC + nnz( logical( TXENCODED ) ~= logical( RXDECODED ) ) ;
		nFrames			= nFrames + 1 ;
		nBits			= nBits + mod.dbpf ;
		nBitsECC		= nBitsECC + mod.bpf ;
		nIter			= nIter + sum( Iter ) ;
		ITER( nFrames, : ) = Iter ;

		%detection of jamming - run of maximum Nr. of iterations
		jamDetected = detectRun( Iter, dec.nIter, 2 ) ;
		if jamDetected
			disp('jammer detected') ;
		end
	
		assert( prod( size( TXDATA ) ) == mod.dbpf ) ;
		assert( prod( size( TXENCODED ) ) == mod.bpf ) ;
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
	sim.ERRECC( x )	= sim.ERRECC( x ) + nErrECC ;
	sim.DBits( x )	= sim.DBits( x ) + nBits ;
	sim.CBits( x )	= sim.CBits( x ) + nBitsECC ;
	sim.Frames( x )	= sim.Frames( x ) + nFrames ;
	sim.BER( x )	= sim.ERR( x ) / sim.DBits( x ) ;
	sim.BERECC( x )	= sim.ERRECC( x ) / sim.CBits( x ) ;
	sim.SNR( x )	= chan.snr ;
	sim.AIT( x )	= nIter / ( nFrames * mod.ospf ) ;
	fprintf('EbN0:%d,SNR:%2.1f,erU:%d,erC:%d,bits:%d,BER:%e,BERECC:%e\n', ...
		EbN0, chan.snr, nErr, nErrECC, nBits, sim.BER( x ), sim.BERECC( x ) ) ;
	if sim.debug
		break ;
	end
end

%% postprocessing --------------------------------------------------------
[ CI, err ] = confidenceInterval( sim.S, sim.BER, sim.DBits ) ;

if ~sim.debug
	if sim.plot
		f = figure() ;
		% subplot( 1, 2, 1 ) ;
		% semilogy( sim.EbN0, sim.BER ) ;
		% grid on ;
		% subplot( 1, 2, 2 ) ;
		set( gcf, 'color', 'w' ) ;
		errorbar( sim.EbN0, sim.BER, err ) ;
		hold on ;
		plot( sim.EbN0, sim.BERECC ) ;
		grid on ;
		set(gca, 'YScale', 'log') 
		xlabel('Eb/No [dB]') ;
		ylabel('BER') ;
		title( mod.type + " M: " + mod.M + " differential: " + mod.diff + " minimum err: " + sim.minErr ) ;
		grid on ;
		hold on ;
	end
end

EBN0	= sim.EbN0
FRAMES	= sim.Frames
DBits	= sim.DBits
ERR		= sim.ERR
BER		= sim.BER
SNR		= sim.SNR

whos ITER
NFRMAES = nFrames
figure( f ) ;



