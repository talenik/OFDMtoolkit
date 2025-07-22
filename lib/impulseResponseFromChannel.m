function [ Hn, Tm ] = impulseResponseFromChannel( channel, ts )
%[ Hn, Tm ] = impulseResponseFromChannel( channel, ts )
% calculates the channel impulse response, and max excess delay in samples
% channel filtering must be turned on
	
chi		= info( channel ) ;
fild	= chi.ChannelFilterDelay ;

nsamp		= ceil( channel.PathDelays( end ) / ts ) ;
unitPulse	= [ 1 ; zeros( nsamp * 2, 1 ) ] ;

faded		= channel( unitPulse ) ;

last		= find( faded, 1, 'last' ) ;		%simulation time impulse response
Hn			= faded( 1 : last ) ;
Hn			= Hn( fild + 1 : end ) ;
Tm			= size( Hn, 1 ) ;					%max excess delay

