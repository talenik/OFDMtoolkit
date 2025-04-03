EBN0     = [ 1		1.2		  1.4     1.6       1.8        1.9           2 ] 
DBits    = [ 163840 327680 983040 7864320 280494080 2163343360 30499307520 ]
%umelo znizime aby bolo nieco vidno
DBit2    = [ 1638 3276 9830 78643 2804940 21633433 304993075 ]

ERR1     = [ 12059  13275  10546  10037  10003  10002  10010 ] 
ERR2     = [ 11935  13540  10825   9532   9900   9785   9912 ] 

BER1	 = [ 7.2845e-02   4.1321e-02   1.1012e-02   1.2121e-03   3.5295e-05   4.5231e-06   3.2499e-07 ]
BER2	 = [ 7.3602e-02   4.0512e-02   1.0728e-02   1.2763e-03   3.5662e-05   4.6234e-06   3.2820e-07 ]

S = 0.99 % pravdep, ze skutocna BER bude v I

% figure( 1 ) ;
% semilogy( EBN0, BER1 ) ;
% 
% figure( 2 ) ;
% plot( EBN0, BER1 )
% grid on ;
% set(gca, 'YScale', 'log') 
%yscale log	%since R2023b LOL


[ CI, err ] = confidenceInterval( S, BER1, DBits )
figure( 1 ) ;
set(gcf,'color','w');

subplot( 1, 2 , 2 )
errorbar( EBN0, BER1, err )
grid on ;
set(gca, 'YScale', 'log') 

xlabel('Eb/No [dB]') ;
ylabel('BER') ;

[ CI, err ] = confidenceInterval( S, BER1, DBit2 )
%figure( 2 ) ;
subplot( 1, 2 , 1 )
errorbar( EBN0, BER1, err )
grid on ;
set(gca, 'YScale', 'log') 
%set(gcf,'color','w');
xlabel('Eb/No [dB]') ;
ylabel('BER') ;


function [ CI, err ] = confidenceInterval( S, BER, bits )
	l = length( BER ) ;
	if l ~=  length( bits )
		error('input size mismatch') ;
	end
	CI	= zeros( 2, l ) ;
	err = zeros( 1, l ) ;

	for i = 1 : l
		p	= BER( i ) ;
		r	= bits( i ) ;

		A	= accuracy( p, r ) 
		k	= confIfraction( A, S ) 
		T	= p * [ 1 - k, 1 + k ]'  

		CI( :, i )	= T
		err( i )	= p * k ; 
	end
end

function k = confIfraction( A, S )
	k = sqrt( 2 / A ) * erfinv( S ) ;
end

function A = accuracy( p, r )
	A = p * r / ( 1 - p ) ;
end

%{
Full simulation log file:
    {'Simulation LDPC with random and fixed RL modifier results:'                                                              }
    {'k:         4096'                                                                                                         }
    {'n:         10240'                                                                                                        }
    {'R:         0.4'                                                                                                          }
    {'Eb/N0:     2'                                                                                                            }
    {'DBits:     30499307520'                                                                                                  }
    {'Errors1:   10010'                                                                                                        }
    {'Errors2:   9912'                                                                                                         }
    {'BER1:      3.282e-07'                                                                                                    }
    {'BER2:      3.2499e-07'                                                                                                   }
    {'telaps:    07:44:53'                                                                                                     }
    {' '                                                                                                                       }
    {'EBN0     = [ 1         1.2         1.4         1.6         1.8         1.9           2 ] '                               }
    {'NBlocks  = [ 1       2       6      48    1712   13204  186153 ] '                                                       }
    {'DBits    = [ 163840       327680       983040      7864320    280494080   2163343360  30499307520 ] '                    }
    {'TElaps   = [ 0.204057         0.39958        1.217734        9.312566      295.963989      2116.02062      27893.1002 ] '}
    {'ERR1     = [ 12059  13275  10546  10037  10003  10002  10010 ] '                                                         }
    {'ERR2     = [ 11935  13540  10825   9532   9900   9785   9912 ] '                                                         }
    {'BER1     = [ 0.073602    0.040512    0.010728   0.0012763  3.5662e-05  4.6234e-06   3.282e-07 ] '                        }
    {'BER2     = [ 0.072845    0.041321    0.011012   0.0012121  3.5295e-05  4.5231e-06  3.2499e-07 ] '                        }
    {' '                                                                                                                       }
    {'Total simulated bits:  32952483840'                                                                                      }
    {'Total simulation time: 30316.2188'                                                                                       }
    {'Simulation throughput: 1086958901825.446 Mbps'                                                                           }
Simulation finished in: 08:25:16
EBN0 =
   1.0000e+00   1.2000e+00   1.4000e+00   1.6000e+00   1.8000e+00   1.9000e+00   2.0000e+00
BER =
   7.3602e-02   4.0512e-02   1.0728e-02   1.2763e-03   3.5662e-05   4.6234e-06   3.2820e-07
   7.2845e-02   4.1321e-02   1.1012e-02   1.2121e-03   3.5295e-05   4.5231e-06   3.2499e-07
%}