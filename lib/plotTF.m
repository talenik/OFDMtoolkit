function plotTF( Xt, Xf ) 

figure ;
subplot( 1, 2, 1 ) ;
stem( abs( Xt ) ) ;

subplot( 1, 2, 2 ) ;
plot( 10 * log10( abs( Xf ) ) ) ;