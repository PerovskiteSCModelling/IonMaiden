function JJJ = AnJac(t,u,params,vectors,matrices,flag)
% This function defines the analytical Jacobian of the RHS. This matrix is
% passed to ode15s via the Jacobian option. The input is a structure
% containing the necessary parameters. The last input, flag, is an optional
% argument which is used to adapt the function, e.g. to simulate
% open-circuit conditions.

% Input parameters and arrays
[chi, delta, R, lambda, lam2, Rr, Rl, N, Kn, Kp, NE, lamE2, KE, kE, rE, ...
    NH, lamH2, KH, kH, rH, DI, atol, ARs, Rsp] ...
    = struct2array(params,{'chi','delta','R','lambda','lam2','Rr','Rl', ...
                           'N','Kn','Kp','NE','lamE2','KE','kE','rE', ...
                           'NH','lamH2','KH','kH','rH','DI','atol', ...
                           'ARs','Rsp'});
[dx, dxE, dxH, xd, xdE, xdH] ...
    = struct2array(vectors,{'dx','dxE','dxH','xd','xdE','xdH'});
[JJJ, Av, AvE, AvH, Lo, LoE, LoH, Dx, DxE, DxH] ...
    = struct2array(matrices,{'JJJ','Av','AvE','AvH','Lo','LoE','LoH', ...
                             'Dx','DxE','DxH'});

% Use the rtol parameter for the finite difference approximation
% of the net generation and recombination rates (GR, Rr and Rl)
del = atol;

% Assign variable names
P   = u(1:N+1,:);
phi = u(N+2:2*N+2,:);
n   = u(2*N+3:3*N+3,:);
p   = u(3*N+4:4*N+4,:);
phiE = [u(4*N+5:4*N+NE+4,:); phi(1,:)];
nE   = [u(4*N+NE+5:4*N+2*NE+4,:); n(1,:)];
phiH = [phi(end,:); u(4*N+2*NE+5:4*N+2*NE+NH+4,:)];
pH   = [p(end,:); u(4*N+2*NE+NH+5:4*N+2*NE+2*NH+4,:)];

% Compute variables (at the half points)
mE = Dx*phi; % negative electric field
mEE = DxE*phiE; % negative electric field in ETL
mEH = DxH*phiH; % negative electric field in HTL
AvP = Av*P; % averaged anion vacancy density
Avn = Av*n; % averaged electron density
AvnE = AvE*nE; % averaged electron density in ETL
Avp = Av*p; % averaged hole density
AvpH = AvH*pH; % averaged hole density in HTL
RR = R(Avn,Avp,AvP); % bulk recombination rate
RRn = R(Avn+del/2,Avp,AvP);
RRp = R(Avn,Avp+del/2,AvP);
RRP = R(Avn,Avp,AvP+del/2);

% P equation depends on P
JJJ(1:N+1,1:N+1) = nnz(DI)*lambda*gallery('tridiag',N+1, ...
    xd-mE/2, ...
    [-xd(1)+mE(1)/2; -xd(1:N-1)-mE(1:N-1)/2-xd(2:N)+mE(2:N)/2; ...
        -xd(N)-mE(N)/2], ...
    xd+mE/2);
% P equation depends on phi
JJJ(1:N+1,N+2:2*N+2) = nnz(DI)*lambda*gallery('tridiag',N+1, ...
    AvP./dx, ...
    [-AvP(1)./dx(1); -AvP(1:N-1)./dx(1:N-1)-AvP(2:N)./dx(2:N); -AvP(N)./dx(N)], ...
    AvP./dx);
% P equation does not depend on n
% P equation does not depend on p
% P equation does not depend on phiE
% P equation does not depend on nE
% P equation does not depend on phiH
% P equation does not depend on pH

% phi equation depends on P
JJJ(N+2,1:2) = dx(1)*[1/3, 1/6]/lam2;
JJJ(N+3:2*N+1,1:N+1) = Lo/lam2;
JJJ(2*N+2,N:N+1) = dx(end)*[1/6, 1/3]/lam2;
% phi equation depends on phi
JJJ(N+2:2*N+2,N+2:2*N+2) = gallery('tridiag',N+1, ...
    xd, ...
    [-xd(1)-rE.*xdE(end); -xd(1:N-1)-xd(2:N); ...
        -xd(end)-rH.*xdH(1)], ...
    xd);
% phi equation depends on n
JJJ(N+2,2*N+3:2*N+4) = -delta*[(dxE(end)/kE+dx(1))/3, dx(1)/6]/lam2;
JJJ(N+3:2*N+1,2*N+3:3*N+3) = -delta*Lo/lam2;
JJJ(2*N+2,3*N+2:3*N+3) = -delta*dx(end)*[1/6, 1/3]/lam2;
% phi equation depends on p
JJJ(N+2,3*N+4:3*N+5) = delta*chi*dx(1)*[1/3, 1/6]/lam2;
JJJ(N+3:2*N+1,3*N+4:4*N+4) = delta*chi*Lo/lam2;
JJJ(2*N+2,4*N+3:4*N+4) = delta*chi*[dx(end)/6, (dx(end)+dxH(1)/kH)/3]/lam2;
% phi equation depends on phiE
JJJ(N+2,4*N+NE+4) = rE./dxE(end);
% phi equation depends on nE
JJJ(N+2,4*N+2*NE+4) = -rE*dxE(end)/6/lamE2;
% phi equation depends on phiH
JJJ(2*N+2,4*N+2*NE+5) = rH./dxH(1);
% phi equation depends on pH
JJJ(2*N+2,4*N+2*NE+NH+5) = rH*dxH(1)/6/lamH2;

% n equation can depend on P via GR
JJJ(2*N+3:3*N+3,1:N+1) = -1/2*gallery('tridiag',N+1, ...
    dx.*(RRP-RR)/del, ...
    [dx(1).*(RRP(1)-RR(1))/del; (dx(2:N).*(RRP(2:N)-RR(2:N))+dx(1:N-1).*(RRP(1:N-1)-RR(1:N-1)))/del; ...
        dx(N)*(RRP(N)-RR(N))/del], ...
    dx.*(RRP-RR)/del);
% n equation depends on phi
JJJ(2*N+3:3*N+3,N+2:2*N+2) = -Kn*gallery('tridiag',N+1, ...
    Avn./dx, ...
    [-KE/Kn*AvnE(end)./dxE(end)-Avn(1)./dx(1); ...
        -Avn(2:N)./dx(2:N)-Avn(1:N-1)./dx(1:N-1); -Avn(N)./dx(N)], ...
    Avn./dx);
% n equation depends on n
JJJ(2*N+3:3*N+3,2*N+3:3*N+3) = Kn*gallery('tridiag',N+1, ...
    xd+mE/2, ...
    [KE/Kn*(-xdE(end)+mEE(end)/2)-xd(1)-mE(1)/2; ...
        -xd(1:N-1)+mE(1:N-1)/2-xd(2:N)-mE(2:N)/2; -xd(N)+mE(N)/2], ...
    xd-mE/2);
% n equation also depends on n via GR, Rl and Rr
JJJ(2*N+3:3*N+3,2*N+3:3*N+3) = JJJ(2*N+3:3*N+3,2*N+3:3*N+3) ...
    -1/2*gallery('tridiag',N+1, ...
    dx.*(RRn-RR)/del, ...
    [(dx(1).*(RRn(1)-RR(1))+2*(Rl(n(1)+del,p(1))-Rl(n(1),p(1))))/del; ...
        (dx(2:N).*(RRn(2:N)-RR(2:N))+dx(1:N-1).*(RRn(1:N-1)-RR(1:N-1)))/del; ...
        (dx(N)*(RRn(N)-RR(N))+2*(Rr(n(N+1)+del,p(N+1))-Rr(n(N+1),p(N+1))))/del], ...
    dx.*(RRn-RR)/del);
% n equation depends on p via GR, Rl and Rr
JJJ(2*N+3:3*N+3,3*N+4:4*N+4) = -1/2*gallery('tridiag',N+1, ...
    dx.*(RRp-RR)/del, ...
    [(dx(1).*(RRp(1)-RR(1))+2*(Rl(n(1),p(1)+del)-Rl(n(1),p(1))))/del; ...
        (dx(2:N).*(RRp(2:N)-RR(2:N))+dx(1:N-1).*(RRp(1:N-1)-RR(1:N-1)))/del; ...
        (dx(N)*(RRp(N)-RR(N))+2*(Rr(n(N+1),p(N+1)+del)-Rr(n(N+1),p(N+1))))/del], ...
    dx.*(RRp-RR)/del);
% n equation depends on phiE
JJJ(2*N+3,4*N+NE+4) = -KE*AvnE(end)./dxE(end);
% n equation depends on nE
JJJ(2*N+3,4*N+2*NE+4) = KE*(xdE(end)+mEE(end)/2);
% n equation does not depend on phiH
% n equation does not depend on pH

% p equation can depend on P via GR
JJJ(3*N+4:4*N+4,1:N+1) = -1/2*gallery('tridiag',N+1, ...
    dx.*(RRP-RR)/del, ...
    [dx(1)*(RRP(1)-RR(1))/del; ...
        (dx(2:N).*(RRP(2:N)-RR(2:N))+dx(1:N-1).*(RRP(1:N-1)-RR(1:N-1)))/del; ...
        dx(N).*(RRP(N)-RR(N))/del], ...
    dx.*(RRP-RR)/del);
% p equation depends on phi
JJJ(3*N+4:4*N+4,N+2:2*N+2) = Kp*gallery('tridiag',N+1, ...
    Avp./dx, ...
    [-Avp(1)./dx(1); -Avp(1:N-1)./dx(1:N-1)-Avp(2:N)./dx(2:N); ...
        -Avp(N)./dx(N)-KH/Kp*AvpH(1)./dxH(1)], ...
    Avp./dx);
% p equation depends on n via GR, Rl and Rr
JJJ(3*N+4:4*N+4,2*N+3:3*N+3) = -1/2*gallery('tridiag',N+1, ...
    dx.*(RRn-RR)/del, ...
    [(dx(1)*(RRn(1)-RR(1))+2*(Rl(n(1)+del,p(1))-Rl(n(1),p(1))))/del; ...
        (dx(2:N).*(RRn(2:N)-RR(2:N))+dx(1:N-1).*(RRn(1:N-1)-RR(1:N-1)))/del; ...
        (dx(N).*(RRn(N)-RR(N))+2*(Rr(n(N+1)+del,p(N+1))-Rr(n(N+1),p(N+1))))/del], ...
    dx.*(RRn-RR)/del);
% p equation depends on p
JJJ(3*N+4:4*N+4,3*N+4:4*N+4) = Kp*gallery('tridiag',N+1, ...
    xd-mE/2, ...
    [-xd(1)+mE(1)/2; -xd(1:N-1)-mE(1:N-1)/2-xd(2:N)+mE(2:N)/2; ...
        -xd(N)-mE(N)/2+KH/Kp*(-xdH(1)+mEH(1)/2)], ...
    xd+mE/2);
% p equation also depends on p via GR, Rl and Rr
JJJ(3*N+4:4*N+4,3*N+4:4*N+4) = JJJ(3*N+4:4*N+4,3*N+4:4*N+4) ...
    -1/2*gallery('tridiag',N+1, ...
    dx.*(RRp-RR)/del, ...
    [(dx(1)*(RRp(1)-RR(1))+2*(Rl(n(1),p(1)+del)-Rl(n(1),p(1))))/del; ...
        (dx(2:N).*(RRp(2:N)-RR(2:N))+dx(1:N-1).*(RRp(1:N-1)-RR(1:N-1)))/del; ...
        (dx(N).*(RRp(N)-RR(N))+2*(Rr(n(N+1),p(N+1)+del)-Rr(n(N+1),p(N+1))))/del], ...
    dx.*(RRp-RR)/del);
% p equation does not depend on phiE
% p equation does not depend on nE
% p equation depends on phiH
JJJ(4*N+4,4*N+2*NE+5) = KH*AvpH(1)./dxH(1);
% p equation depends on pH
JJJ(4*N+4,4*N+2*NE+NH+5) = KH*(xdH(1)+mEH(1)/2);

% Rescale the first n and last p equation to be the same as the TLs
JJJ(2*N+3,:) = kE*JJJ(2*N+3,:);
JJJ(4*N+4,:) = kH*JJJ(4*N+4,:);

% phiE equation does not depend on P
% phiE equation depends on phi
JJJ(4*N+NE+4,N+2) = xdE(end);
% phiE equation depends on n
JJJ(4*N+NE+4,2*N+3) = -dxE(end)/6/lamE2;
% phiE equation does not depend on p
% phiE equation depends on phiE
JJJ(4*N+5:4*N+NE+4,4*N+5:4*N+NE+4) = gallery('tridiag',NE, ...
    xdE(1:NE-1), ...
    [1; -xdE(1:NE-1)-xdE(2:NE)], ...
    [0; xdE(2:NE-1)]);
% phiE equation depends on nE
JJJ(4*N+6:4*N+NE+4,4*N+NE+5:4*N+2*NE+4) = -LoE(:,1:NE)/lamE2;
% phiE equation does not depend on phiH
% phiE equation does not depend on pH

% nE equation does not depend on P
% nE equation depends on phi
JJJ(4*N+2*NE+4,N+2) = -kE*KE*AvnE(end)./dxE(end);
% nE equation depends on n
JJJ(4*N+2*NE+4,2*N+3) = kE*KE*(xdE(end)-mEE(end)/2);
% nE equation does not depend on p
% nE equation depends on phiE
JJJ(4*N+NE+5:4*N+2*NE+4,4*N+5:4*N+NE+4) = -kE*KE*gallery('tridiag',NE, ...
    AvnE(1:NE-1)./dxE(1:NE-1), ...
    [0; -AvnE(1:NE-1)./dxE(1:NE-1)-AvnE(2:NE)./dxE(2:NE)], ...
    [0; AvnE(2:NE-1)./dxE(2:NE-1)]);
% nE equation depends on nE
JJJ(4*N+NE+5:4*N+2*NE+4,4*N+NE+5:4*N+2*NE+4) = kE*KE*gallery('tridiag',NE, ...
    xdE(1:NE-1)+mEE(1:NE-1)/2, ...
    [1/(kE*KE); -xdE(1:NE-1)+mEE(1:NE-1)/2-xdE(2:NE)-mEE(2:NE)/2;], ...
    [0; xdE(2:NE-1)-mEE(2:NE-1)/2]);
% nE equation does not depend on phiH
% nE equation does not depend on pH

% phiH equation does not depend on P
% phiH equation depends on phi
JJJ(4*N+2*NE+5,2*N+2) = xdH(1);
% phiH equation does not depend on n
% phiH equation depends on p
JJJ(4*N+2*NE+5,4*N+4) = dxH(1)/6/lamH2;
% phiH equation does not depend on phiE
% phiH equation does not depend on nE
% phiH equation depends on phiH
JJJ(4*N+2*NE+5:4*N+2*NE+NH+4,4*N+2*NE+5:4*N+2*NE+NH+4) = gallery('tridiag',NH, ...
    [xdH(2:NH-1); 0], ...
    [-xdH(1:NH-1)-xdH(2:NH); 1], ...
    xdH(2:NH));
% phiH equation depends on pH
JJJ(4*N+2*NE+5:4*N+2*NE+NH+3,4*N+2*NE+NH+5:4*N+2*NE+2*NH+4) = LoH(:,2:NH+1)/lamH2;

% pH equation does not depend on P
% pH equation depends on phi
JJJ(4*N+2*NE+NH+5,2*N+2) = kH*KH*AvpH(1)./dxH(1);
% pH equation does not depend on n
% pH equation depends on p
JJJ(4*N+2*NE+NH+5,4*N+4) = kH*KH*(xdH(1)-mEH(1)/2);
% pH equation does not depend on phiE
% pH equation does not depend on nE
% pH equation depends on phiH
JJJ(4*N+2*NE+NH+5:4*N+2*NE+2*NH+4,4*N+2*NE+5:4*N+2*NE+NH+4) = ...
    kH*KH*gallery('tridiag',NE, ...
    [AvpH(2:NH-1)./dxH(2:NH-1); 0], ...
    [-AvpH(1:NH-1)./dxH(1:NH-1)-AvpH(2:NH)./dxH(2:NH); 0], ...
    AvpH(2:NH)./dxH(2:NH));
% pH equation depends on pH
JJJ(4*N+2*NE+NH+5:4*N+2*NE+2*NH+4,4*N+2*NE+NH+5:4*N+2*NE+2*NH+4) = ...
    kH*KH*gallery('tridiag',NH, ...
    [xdH(2:NH-1)-mEH(2:NH-1)/2; 0], ...
    [-xdH(1:NH-1)-mEH(1:NH-1)/2-xdH(2:NH)+mEH(2:NH)/2; 1/(kH*KH)], ...
    xdH(2:NH)+mEH(2:NH)/2);

% Adjust right-hand potential BC to account for any parasitic resistance
JJJ(4*N+2*NE+NH+4,4*N+2*NE+NH+3:4*N+2*NE+NH+4) ...
    = [0,1]+KH*[-1,1]*AvpH(end)./dxH(end)*ARs/(1+Rsp);
JJJ(4*N+2*NE+NH+4,4*N+2*NE+2*NH+3:4*N+2*NE+2*NH+4) ...
    = KH*[-xdH(end)+mEH(end)/2,xdH(end)+mEH(end)/2]*ARs/(1+Rsp);

% Perform any additional step requested by the optional input argument flag
if nargin>5
    if strcmp(flag,'none')
        % Do nothing else
    elseif strcmp(flag,'open-circuit')
        % Overwrite the entries for the potential at each contact
        % Zero current boundary condition:
        JJJ(4*N+5,:) = kE*KE*[zeros(1,4*N+4), ...
                              AvnE(1)./dxE(1), -AvnE(1)./dxE(1), ...
                              zeros(1,NE-2), ...
                              -xdE(1)-mEE(1)/2, xdE(1)-mEE(1)/2, ...
                              zeros(1,NE-2+2*NH)];
        % Symmetric values of the potential at the contacts
        JJJ(4*N+2*NE+NH+4,:) = [zeros(1,4*N+4), 1, zeros(1,2*NE-1), ...
                                zeros(1,NH-1), 1, zeros(1,NH)];
    elseif strcmp(flag,'init')
        % Overwrite right-hand BC to ensure conservation of ion vacancies
        JJJ(N+1,:) = [dx(1)/2, (dx(2:N)+dx(1:N-1))'/2, dx(N)/2, ...
                      zeros(1,3*N+2*NE+2*NH+3)];
    elseif strcmp(flag,'findVoc')
        % Overwrite the entries for the potential at each contact
        % Zero current boundary condition:
        JJJ(4*N+5,:) = kE*KE*[zeros(1,4*N+4), ...
                              AvnE(1)./dxE(1), -AvnE(1)./dxE(1), ...
                              zeros(1,NE-2), ...
                              -xdE(1)-mEE(1)/2, xdE(1)-mEE(1)/2, ...
                              zeros(1,NE-2+2*NH)];
        % Symmetric values of the potential at the contacts
        JJJ(4*N+2*NE+NH+4,:) = [zeros(1,4*N+4), 1, zeros(1,2*NE-1), ...
                                zeros(1,NH-1), 1, zeros(1,NH)];
        % Overwrite right-hand BC to ensure conservation of ion vacancies
        JJJ(N+1,:) = [dx(1)/2, (dx(2:N)+dx(1:N-1))'/2, dx(N)/2, ...
                      zeros(1,3*N+2*NE+2*NH+3)];
    else
        error('The optional input argument is not recognised.');
    end
end

end
