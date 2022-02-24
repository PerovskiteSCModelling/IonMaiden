function [S, Sinv, A] = create_stats_funcs(stats)
% Creates an efficient and accurate numerical approximation to a statistical
% function and its inverse. Statistical models are specified by a structure
% with the fields 'model' and 'Boltzmann'. Supported models are 'FermiDirac',
% 'GaussFermi' and 'Blakemore'. The GaussFermi model requires
% an extra parameter, 's', giving the dimensionless Gaussian disorder of
% the relevent band. The Blakemore model requires an additional parameter
% 'lim' that gives the limiting dimensionless concentration. The outputs
% are the statistical function S, its inverse Sinv, and the Boltzmann
% approximation constant A.

[model, Boltzmann, s, lim] = struct2array(stats, {'model', 'Boltzmann', 's', 'lim'});

if isequal(model, 'FermiDirac')
    if Boltzmann
        % Boltzmann approximation to Fermi-Dirac statistics
        Sinv = @(x) log(x);
        S = @(x) exp(x);
    else
        % Create lookup table using numerical integration
        cmin = 1e-7; % minimum concentration required (dimensionless)
        Ntab=2e3; % number of tabulated points
        xi=linspace(log(cmin), 6, Ntab); % dimensionless Fermi levels
        FD=FermiDirac(xi,1e3); % compute corresponding concentrations via numerical integration
        S=@(E) interp1(xi,FD, E, 'pchip', NaN); % create tabulated function
        Sinv=@(c) interp1(FD, xi, c, 'pchip', NaN); % create tabulated inverse function
    end
    A = 1; % Boltzmann approximation constant
    if ~isempty(s),
        warning(['The Gaussian disorder parameter was defined but was not ' ...
            'used for the FermiDirac model.']); end
elseif isequal(model, 'GaussFermi')
    if isempty(s)
        error(['The GaussFermi statistical model requires the Gaussian ' ...
            'disorder parameter (s). See the user guide for more information'])
    end
    if Boltzmann
        % Boltzmann approximation to Gauss-Fermi statistics
        Sinv = @(x) log(x) - s^2/2;
        S = @(x) exp(x + s^2/2);
        A = 1;% Boltzmann approximation constant
    else
        if s==0
            Sinv = @(x) BlakemoreInv(x,1); % Exact limit of vanishing s
            S = @(x) 1./(exp(-x)+1);
            A = 1; % Boltzmann approximation constant
        else
            % Create lookup table using numerical integration
            cmin = 1e-12; % minimum concentration required
            Ntab=2e3; % number of tabulated points
            xi=linspace(log(cmin)-s^2/2, 2*s, Ntab); % dimensionless Fermi levels
            GF=GaussFermi(xi,s,1e3); % compute corresponding concentrations
            S=@(E) interp1(xi,GF, E, 'pchip', nan); % create tabulated function
            Sinv=@(c) interp1(GF, xi, c, 'pchip', nan); % create tabulated function
            A = exp(s^2/2); % Boltzmann approximation constant
        end
    end
elseif isequal(model, 'Blakemore')
    if isempty(lim)
        error(['The Blakemore statistical model requires the concentration ' ...
            'limit parameter (lim). See the user guide for more information'])
    end
    if Boltzmann
        Sinv = @(x) log(x);
        S = @(x) exp(x);
        A = 1; % Boltzmann approximation constant
    else
        gamma = 1/lim;
        Sinv = @(x) BlakemoreInv(x,gamma);
        S = @(x) 1./(exp(-x)+gamma);
        A = 1; % Boltzmann approximation constant
    end
    
    if ~isempty(s),
        warning(['The Gaussian disorder parameter was defined but was not ' ...
            'used for the Blakemore model.']); end
% % Template for user-defined statistical models
% elseif isequal(model, 'modelname')
%     if Boltzmann
%         Sinv = @(x) log(x); % Boltzmann approximation to inverse function
%         S = @(x) exp(x); % Boltzmann approximation to forwards function
%         A = 1; % Boltzmann approximation constant
%     else
%         Sinv = @(x) log(x); % inverse function
%         S = @(x) exp(x); % forwards function
%         A = 1; % Boltzmann approximation constant
%     end
else
    error(['Statistical model name not recognised. Choose from ''FermiDirac',...
        ''', GaussFermi'', or ''Blakemore''.'])
end

%% 

function F = FermiDirac(xi, N)
% Numerical evaluation of the Fermi-Dirac integral
if any(xi>6)
    error('Fermi level is too high for accurate Fermi-Dirac integral evaluation.')
end
for i=1:length(xi)
    eta=linspace(0, 8 + exp(xi(i)/3), N); % create integration grid
    f = 2/sqrt(pi)*eta.^0.5./(1+exp(eta-xi(i))); % calculate integrand
    F(i) = trapz(eta,f); % numerically integrate using the trapezoid rule
end
end

function G = GaussFermi(xi, s, N)
% Numerical evaluation of the Gauss-Fermi integral
if s<1 
    error('Gaussian width is too low for accurate Gauss-Fermi integral evaluation. Ensure s>=1 or s=0.')
end
if any(xi>2*s)
    error('Fermi level is too high for accurate Gauss-Fermi integral evaluation.')
end

for i=1:length(xi)
    eta=linspace(xi(i)-5*(s), max(0,xi(i))+5*sqrt(s), N); % create integration grid
    f = 1/(s*sqrt(2*pi))*exp(-0.5*(eta/s).^2)./(1 + exp(eta-xi(i))); % calculate integrand
    G(i) = trapz(eta,f); % numerically integrate using the trapezoid rule
end
end

function B = BlakemoreInv(xi, gamma)
    B = log(xi./(1-gamma*xi));
    B(xi>=1/gamma) = inf;
end

end