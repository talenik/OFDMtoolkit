
path( '../', path )	;	%path for secret email config
path( './lib', path ) ;
path( './LDPC', path ) ;
path( './MEX', path ) ;

cl ;

std = 'wifi' 
N	= 1944 
R	= 1 / 2 
cod	= loadQCLDPC( std, R, N ) 
cod.Rc = cod.R ;

enc = QCLDPCEncode() ; 		
dec = QCLDPCDecode() ;

dec.nIter	= 20 ;
dec.nthread = 16 ;
dec.build	= 'release' ;
dec.dbglev	= 1 ;
dec.method  = 'float' ;

sim = WTF() ;
sim.EbN0	= [ [ 1 : 0.2 : 2.4 ] ] ;
sim.blkSize	= 10 * dec.nthread ;
sim.minErr	= 100 ;	%minimum nr. of errors for each Eb/N0 point
sim.prof	= false ;	%profile code and show HTML report
sim.single	= false ;	%just testrun one loop of the simulation
sim.report	= false ;	%send email after each iteration is finished
sim.plot	= false ;	%plot waterfall figure in the end
sim.save	= false ;	%save results to local .mat file immediately in WTF
sim.impl	= 'MEX' ;
sim.maxBlocks = 1e4 ;

saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;
buildMEXfile( enc ) ;
buildMEXfile( dec ) ;

enc
dec
sim

disp( [ 'Running sim for: ' std, ' with: ' n2s( R ) n2s( N ) ] ) ;

t		= tic ;	
[ res, ITER ]	= WTF( cod, enc, dec, sim ) ;
disp( datestr( datenum( 0, 0, 0, 0, 0, toc( t )), "DD:HH:MM:SS" ) ) ;

AIT		= res.ITER
plotWTF( res, 'WIFI6', R, N ) ;
res
