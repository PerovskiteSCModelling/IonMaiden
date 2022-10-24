function sol_init = apply_Poisson(sol_init,params,vectors,matrices)
% This function applies the algebraic equations corresponding to Poisson's
% equation for the electric potential to a vector of the solution variables
% (sol_init) in order to ensure that Poisson's equation is satisfied as
% precisely as can be achieved by mldivide. The other inputs are structures
% containing the necessary parameters, vectors and matrices for the
% computation.

% Parameter input
[delta, chi, lam2, lamE2, lamH2, N, NE, NH, rE, rH, Pm, NonlinearFP] ...
    = struct2array(params, {'delta','chi','lam2','lamE2','lamH2', ...
    'N','NE','NH','rE','rH','Pm','NonlinearFP'});
[dx, dxE, dxH] = struct2array(vectors, {'dx','dxE','dxH'});
[Lo, LoE, LoH, NN, ddE, ddH] ...
    = struct2array(matrices,{'Lo','LoE','LoH','NN','ddE','ddH'});

% Ensure that the vacancy density does not exceeed the maximum density
if any(Pm) && strcmp(NonlinearFP,'Diffusion')
    sol_init(1:N+1) = min(1/Pm,sol_init(1:N+1));
end

% Assign variable names
P   = sol_init(1:N+1);
phi = sol_init(N+2:2*N+2);
n   = sol_init(2*N+3:3*N+3);
p   = sol_init(3*N+4:4*N+4);
phiE = [sol_init(4*N+5:4*N+NE+4); phi(1)];
nE   = sol_init(4*N+NE+5:4*N+2*NE+5);
phiH = [phi(end); sol_init(4*N+2*NE+6:4*N+2*NE+NH+5)];
pH   = sol_init(4*N+2*NE+NH+6:4*N+2*NE+2*NH+6);

% Algebraic equations corresponding to Poisson's equation
A = gallery('tridiag',N+NE+NH-1, ...
    [1./dxE(2:end-1); rE./dxE(end); 1./dx; 1./dxH(1:end-1)], ...
    [-(1./dxE(1:end-1)+1./dxE(2:end)); -(rE./dxE(end)+1./dx(1)); ...
    -(1./dx(1:end-1)+1./dx(2:end)); -(1./dx(end)+rH./dxH(1)); ...
    -(1./dxH(1:end-1)+1./dxH(2:end))], ...
    [1./dxE(2:end); 1./dx; rH./dxH(1); 1./dxH(2:end-1)]);
B(1:NE-1,1) = (LoE*nE-ddE)/lamE2; % charge density in ETL
B(1) = B(1)-phiE(1)/dxE(1); % to take account of contact potential
B(NE,1) = dx(1)*(1/2-P(1)/3-P(2)/6 ...
        +delta*(n(1)/3+n(2)/6 ...
        -chi*(p(1)/3+p(2)/6)))/lam2 ...
        +rE*dxE(end)*(nE(NE)/6 ...
        +nE(NE+1)/3-1/2)/lamE2; % continuity
B(NE+1:N+NE-1,1) = (NN-Lo*P+delta*(Lo*n ...
        -chi*Lo*p))/lam2; % charge density
B(N+NE,1) = dx(end)*(1/2-P(end-1)/6-P(end)/3 ...
        +delta*(n(end-1)/6+n(end)/3 ...
        -chi*(p(end-1)/6+p(end)/3)))/lam2 ...
        +rH*dxH(1)*(1/2-pH(1)/3-pH(2)/6)/lamH2; % continuity
B(N+NE+1:N+NE+NH-1,1) = (ddH-LoH*pH)/lamH2; % charge density in HTL
B(N+NE+NH-1) = B(N+NE+NH-1)-phiH(end)/dxH(end); % contact
sol_init([4*N+6:4*N+NE+4,N+2:2*N+2,4*N+2*NE+6:4*N+2*NE+NH+4]) = mldivide(A,B);

end
