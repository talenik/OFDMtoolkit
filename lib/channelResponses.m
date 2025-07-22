function [ Hn, Hk, Tm ] = channelResponses( channel, ts, N )
%[ Hn, Hk, Tm ] = channelResponses( channel, ts, N )
% calculates the channel impulse and frequency response, and max excess delay in samples
% channel filtering must be turned on
	
chi		= info( channel )
filterM	= chi.ChannelFilterCoefficients ;
filter  = sum( filterM ) ;	%should be real-valued

%normalize the filter to presenve energy
E		= sum( filter .^ 2 ) ;
filter	= filter .* ( 1 / sqrt( E ) ) ;

assert( equals( sum( filter.^2 ), 1, 1e-9) ) ;

delay	= chi.ChannelFilterDelay ;

Hn = filter.' ;
Hk = fft( Hn, N,1 ); 

Tm = size( Hn, 1 ) ;


