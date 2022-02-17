function sol = IS_solver(base_params)
% This function constructs an experimental protocol and obtains a numerical
% solution for each sample frequency in an impedance spectroscopy
% simulation. `base_params` is a parameters structure where
% `base_params.applied_voltage` specifies an impedance protocol.
% The iterative calls to `numericalsolver` will be performed on parallel
% cores if the Parallel Computing Toolbox is installed.

% get values from impedance protocol
nf = base_params.applied_voltage{6}; % number of frequencies to be sampled
fmin = base_params.applied_voltage{2}; % minimum frequency
fmax = base_params.applied_voltage{3}; % maximum frequency
V0 = base_params.applied_voltage{4}; % DC voltage
t = base_params.applied_voltage{8}; % time spent in steady state at DC voltage

% contruct the list of sample frequencies, logarithmically spaced
freqs = logspace(log10(fmin),log10(fmax),nf);

% find steady state at the DC voltage
fprintf('solving for steady state conditions at DC voltage \n')
params = base_params;
params.applied_voltage = {V0,'linear',t,V0}; % steady state protocol

[params.light, params.psi, params.time, params.splits, params.findVoc] = ...
    construct_protocol(params,params.light_intensity, ...
    params.applied_voltage,params.time_spacing);

sol = numericalsolver(params);
dJdt = (sol.J(end)-sol.J(end-1))./(sol.time(end)-sol.time(end-1));
if abs(dJdt)>1e-5
    warning(['Cell may not have reached steady state before impedance ', ...
        'measurements began. Considering increasing the time spent at the DC voltage'])
end

% Save the steady state solution
if ~strcmp(base_params.workfolder(end),'/')
    % modify the path to account for IonMongerLite workfolder
    base_params.workfolder(end+1) = '_';
end
savestr = [base_params.workfolder, 'DC_sol'];
save(savestr,'sol');

if nf>1 ; base_params.Verbose = false; ; end % Supress output during measurements

if ~isempty(ver('parallel')) % check for parallel computing toolbox
    % parallel computing toolbox installed
    pool = gcp;
    fprintf(['\nParallel computing toolbox detected \nBeginning impedance ',...
        'measurements on %s workers \n\n'], num2str(pool.NumWorkers))
    parfor j = 1:nf
        starttime = tic;
        try
            sols(j) = IS_measurement(base_params,freqs(j),savestr);
            sols(j).J(1) = sol.J(end); % replace initial current with steady state value
        catch me
            warning(['frequency ' num2str(j) ' encountered an error'])
            disp( getReport( me, 'extended', 'hyperlinks', 'on' ) )
        end
        fprintf('frequency %s/%s solved in %ss \n',num2str(j),num2str(nf),...
            num2str(toc(starttime)))
    end
else
    % parallel computing toolbox not installed
    fprintf(['\nParallel computing toolbox not detected \nBeginning ',...
        'impedance measurements without parallel computing \n\n'])
    for j = 1:nf
        starttime = tic;
        try
            sols(j) = IS_measurement(base_params,freqs(j),savestr);
            sols(j).J(1) = sol.J(end); % replace initial current with steady state value
        catch me
            warning(['frequency ' num2str(j) ' encountered an error'])
            disp( getReport( me, 'extended', 'hyperlinks', 'on' ) )
        end
        fprintf('frequency %s/%s solved in %ss \n',num2str(j),num2str(nf),...
            num2str(toc(starttime)))
    end
end

for j = 1:length(sols)
    sols(j).impedance_protocol = base_params.applied_voltage; % retain overall protocol
end

%% decide what information to retain in the impedance sol structure

if base_params.reduced_output
    [X,R] = impedance_analysis(sols);
    
    % extract the steady state DC distributions
    dstrbns = struct('P',sol.dstrbns.P(end,:), ...
        'phi',sol.dstrbns.phi(end,:), ...
        'n',sol.dstrbns.n(end,:), ...
        'p',sol.dstrbns.p(end,:), ...
        'phiE',sol.dstrbns.phiE(end,:), ...
        'nE',sol.dstrbns.nE(end,:), ...
        'phiH',sol.dstrbns.phiH(end,:), ...
        'pH',sol.dstrbns.pH(end,:));
    J = sol.J(end);
    Jl = sol.Jl(end);
    Jr = sol.Jr(end);
    
    sol = struct('vectors',sols(1).vectors, ...
        'params',base_params, ...
        'dstrbns',dstrbns, ...
        'J',J, ...
        'Jl',Jl, ...
        'Jr',Jr, ...
        'freqs',freqs, ...
        'R',R, ...
        'X',X);
else
    % retain all information
    sol = sols;
end

end

function sol = IS_measurement(params,freq,savestr)
    % A function to obtain the solution to a single impedance spectroscopy
    % measurement. `base_params` is a parameters structure containing the
    % overall impedance protocol. This function replaces the voltage
    % protocol with a sinusoidal protocol at frequency `freq`. `savestr` is
    % a string specifying the location of the saved file containing the DC
    % steady state solution.
    
    params.UseSplits = false; % avoid making separate calls for consecutive sine waves
    params.input_filename = savestr;
    
    V0 = params.applied_voltage{4}; % DC voltage
    Vp = params.applied_voltage{5}; % AC amplitude
    n_wave = params.applied_voltage{7}; % number of complete sine waves
    
    % construct initial wave
    params.applied_voltage = {'sin',1/freq,V0+Vp}; % first sine wave
    for k = 1:n_wave-1 % add multiple waves
        params.applied_voltage{end+1} = 'sin';
        params.applied_voltage{end+1} = 1/freq;
        params.applied_voltage{end+1} = V0+Vp;
    end
    
    % replace the experimental protocol
    [params.light, params.psi, params.time, params.splits, params.findVoc] = ...
    construct_protocol(params,params.light_intensity,params.applied_voltage,...
        params.time_spacing);
    
    params.splits = [params.splits(1), params.splits(end)]; % avoid making separate calls to solver

    % obtain the solution
    sol = numericalsolver(params);
end


