function [Xhat, usedItr] = decodeLDPC_GPT(H, Zn0, nIter )
	verbose = false ;
	
    Zn0 = Zn0(:);
    [M, N] = size(H);
    row_neighbors = cell(M,1);
    col_neighbors = cell(N,1);
    [mIdx,nIdx] = find(H);
    for k = 1:length(mIdx)
        m = mIdx(k);
        n = nIdx(k);
        row_neighbors{m} = [row_neighbors{m}, n];
        col_neighbors{n} = [col_neighbors{n}, m];
    end
    Lmn = cell(M,1);
    for m = 1:M
        Lmn{m} = zeros(1, length(row_neighbors{m}));
    end
    Znm = cell(N,1);
    for n = 1:N
        Znm{n} = zeros(1, length(col_neighbors{n}));
    end
    if verbose
        fprintf('\nInitial channel LLR (Zn0):\n');
        disp(Zn0.');
    end
    usedItr = nIter;
    for itr = 1:nIter
        for m = 1:M
            nlist = row_neighbors{m};
            Zvals = zeros(size(nlist));
            for iN = 1:length(nlist)
                n = nlist(iN);
                idx_m_in_n = (col_neighbors{n} == m);
                Zvals(iN) = Znm{n}(idx_m_in_n);
            end
            signs = sign(Zvals);
            absVals = abs(Zvals);
            overallSign = prod(signs);
            minVal = min(absVals);
            for iN = 1:length(nlist)
                exSigns = overallSign * signs(iN);
                tmpAbs = absVals;
                tmpAbs(iN) = inf;
                localMin = min(tmpAbs);
                Lmn{m}(iN) = exSigns * localMin;
            end
        end
        for n = 1:N
            mlist = col_neighbors{n};
            Lvals = zeros(1,length(mlist));
            for iM = 1:length(mlist)
                m = mlist(iM);
                idx_n_in_m = (row_neighbors{m} == n);
                Lvals(iM) = Lmn{m}(idx_n_in_m);
            end
            sumAll = sum(Lvals) + Zn0(n);
            for iM = 1:length(mlist)
                Znm{n}(iM) = sumAll - Lvals(iM);
            end
        end
        Xhat = zeros(1,N);
        for n = 1:N
            llr_n = Zn0(n);
            for m = col_neighbors{n}
                idx_n_in_m = (row_neighbors{m} == n);
                llr_n = llr_n + Lmn{m}(idx_n_in_m);
            end
            if llr_n < 0
                Xhat(n) = 1;
            else
                Xhat(n) = 0;
            end
        end
        syndrome = mod(H * Xhat', 2);
        nFails = sum(syndrome);
        if verbose
            fprintf('\n%d-th iteration, # parity fails = %d\n', itr, nFails);
        end
        if ~any(syndrome)
            usedItr = itr;
            if verbose
                fprintf('Decoding converged at iteration %d.\n', itr);
            end
            return;  % return the Xhat and usedItr
        end
    end
    if verbose
        fprintf('\nMax iterations (%d) reached; returning last estimate.\n', nIter);
    end
