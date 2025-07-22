%load 'ITERV.mat' ;
nFranmes = 2680 ;
ospf = 192 ;

II = ITER( 1:nFrames, : ) ;

isolated	= [] ;
run2s		= [] ;
run3s		= [] ;


for f = 1 : nFrames
	I = ITER( f, : ) ;
	if detectRun( f, 20, 1 )
		isolated = [ isolated f ] ;
	end
	if detectRun( f, 20, 2 )
		run2s = [ run2s f ] ;
	end	
	if detectRun( f, 20, 3 )
		run3s = [ run3s f ] ;
	end		
end

li = nnz( ITER == 20 )
li = length( isolated ) 
l2 = length( run2s )
l3 = length( run3s )