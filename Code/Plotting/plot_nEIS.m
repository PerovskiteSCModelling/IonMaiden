function plot_nEIS(sol)
% A function to plot data from impedance spectroscopy simulations. `sol` is
% a solution structure from an IS simulation. This function works for full
% solutions or reduced solutions obtained using the `reduced_output`
% parameter.


%% Extract data

% Check which type of solution structure
if size(sol,2)>1
    % received full solution array
    [X,R] = impedance_analysis(sol);
else
    if ~isfield(sol,'V')
        % received reduced solution structure
        [X,R] = struct2array(sol,{'X','R'});
    else
        % received non-impedance solution structure
        error(['plot_nEIS was given a solution structure that was ', ...
               'not from an impedance simulation.'])
    end
end


%% Default plots

% Set default figure options
set(0,'defaultAxesFontSize',18); % Make axes labels larger
set(0,'defaultTextInterpreter','latex'); % For latex axis labels
set(0,'defaultAxesTickLabelInterpreter','latex'); % For latex tick labels
set(0,'defaultLegendInterpreter','latex'); % For latex legends
M = 2; % marker size
L = 0.5; % line width

for j = 1:size(X,2)
    % Nyquist plot
    figure('Name',['Nyquist plot, order ' num2str(j)]);
    plot(R(:,j),-X(:,j),'-or','LineWidth',L,'MarkerSize',M,'MarkerFaceColor','r');
    grid on;
    set(gca,'DataAspectRatio',[1 1 1]);
    title(['Order ' num2str(j)]);
    if j==3
        ylabel('-Im(Z$_{3}$) / V$^2\Omega$cm$^2$');
        xlabel('Re(Z$_{3}$) / V$^2\Omega$cm$^2$');
    elseif j==2
        ylabel('-Im(Z$_{2}$) / V$\Omega$cm$^2$');
        xlabel('Re(Z$_{2}$) / V$\Omega$cm$^2$');
    else
        ylabel('-Im(Z$_{1}$) / $\Omega$cm$^2$');
        xlabel('Re(Z$_{1}$) / $\Omega$cm$^2$');
    end
end

end
