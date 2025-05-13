function [ RX, vN, NOISE ] = AWGNChan( TX, SNR, mod, cod )
%function [ RX, vN, NOISE ] = AWGNChan( TX, SNR, mod )
%	add AWGN noise to signal, measure signal power for correct SNR
%	expecting approximately unit average signal power
%input:
%	TX	- vector or matrix of real or complex signal space prototypes
%		  real valued (BPSK) sets correct noise power, fixing bug in awgn()
%	SNR - in dB
%	mod - modulator structure, see help modulate
%output:
%	RX	- noisy signal space values
%	vN	- variance of the zero mean AWGN == noise power (linear scale)
%	N	- actual AWNG noise samples


%if signal is previously filtered in fading channel, this must no be true:
%checkPower( TX, 1, 1e-2 ) ;

if isreal( TX )
	%real valued AWGN to be used only with BPSK
	if mod.M ~= 2
		error('modulation order must be 2 for real AWGN') ;
	end

	% Eb == 1, converson see Sklar: Digital communications, Appendix C
	EbN0	= 10 ^ ( SNR / 10 ) ;	
	vN		= 1 / ( 2 * EbN0 * cod.R ) ;	
	NOISE	= sqrt( vN ) * randn( size( TX ) ) ;
	RX		= TX + NOISE ;
	svN		= var( NOISE, 0, 'all' ) ;
	%comparison of sample variance and desired variance
	%TODO: could fail for small TX size
	assert( equals( vN, svN, 1e-1 ) ) ;
	vN		= svN ;
else
	%complex-valued AWGN
	[ RX, vN ]	= awgn( TX, SNR, 'measured' ) ;
	NOISE		= RX - TX ;
end

%if signal is previously filtered in fading channel, this must no be true:
%checkPower( NOISE, vN, 1e-2 ) ;


