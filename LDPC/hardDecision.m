function bits = hardDecision( LLR )

bits = ones( size( LLR ) ) ;
bits( LLR > 0 ) = 0 ;
