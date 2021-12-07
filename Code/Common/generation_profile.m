% A more detailed, charge carrier generation profile specG(x) that
% integrates the absorption spectrum data below. To use this function in
% your simulation, use the following commands your parameters.m file:
% Gspec = generation_profile(alpha,Upsilon,inv);
% G = @(x,t) light(t).*ppval(Gspec,x);
% The inputs are: alpha = (typical) absorption coefficient, Upsilon = 
% alpha*b, where b is the width of the perovskite layer, and inv = 1 for
% standard architecture cells and -1 for inverted. Note that the values of
% the band gap 'Eg' and (total) incident photon flux 'Fph' defined in
% your parameters.m file are also still used for scaling purposes. It is
% assumed that a single electron-hole pair is generated by a single photon.

function Gspec = generation_profile(alpha,Upsilon,inv)

%% Input data

% Import the absorption coefficient (m-1) vs. photon energy (eV) data as
% row vectors. Check that this input is consistent with the band gap Eg and
% (average) absorption coefficient alpha in your parameters.m file.
photon_energies = 1.6:0.1:2.2;
absorption_coeffs = fliplr((0.7:0.1:1.3)*1e7);

% Set the composition of the incident photon flux (m-2s-1) as a function of
% photon energy (should integrate to one)
photon_comp = @(E) (heaviside(E-photon_energies(1))-heaviside(E-photon_energies(end))) ...
                    ./(photon_energies(end)-photon_energies(1));


%% Create function

% Rescale absorption coefficients
absorption_coeffs = absorption_coeffs/alpha;

% Generate a piecewise cubic spline interpolant of the dimensionless
% absorption spectrum (can use spline, pchip or makima)
absorp = spline(photon_energies,absorption_coeffs);

% Define the generation rate corresponding to each photon energy
integrand = @(E,x) ppval(absorp,E).*photon_comp(E) ...
                   .*exp(-Upsilon*ppval(absorp,E).*(inv*x+(1-inv)/2));
    
% Compute the dimensionless integral at a set of points in space
x = 0:0.05:1;
Gvals = Upsilon/(1-exp(-Upsilon)) ...
       .*integral(@(E) integrand(E,x),photon_energies(1),photon_energies(end), ...
                   'ArrayValued',true); % for each value of x

% Generate an interpolant for the integral to enable fast evaluation
Gspec = spline(x,Gvals);

% % Plot the absorption spectrum
% figure;
% subplot(1,2,1); hold on;
% plot(photon_energies,absorption_coeffs*alpha,'kx');
% plot(photon_energies,ppval(absorp,photon_energies)*alpha,'b-');
% xlabel('Photon energy (eV)');
% ylabel('Absorption coefficient (m-1)');
% 
% % Plot the generation profile
% subplot(1,2,2); hold on;
% plot(x*Upsilon/alpha*1e9,Gvals,'kx');
% plot(x*Upsilon/alpha*1e9,ppval(Gspec,x),'b-');
% xlim([0,Upsilon/alpha*1e9]);
% xlabel('Perovskite layer (nm)');
% ylabel('Generation rate (G0)');

end