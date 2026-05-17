% 1. Define Scenario (your own table)
%           t_start  t_end   Dist  L2  L1  R1  R2
scenario = [
    0        5       30      1    0    0    1  ;   % Straight
    5        8       30      1    0    1    1  ;   % Drift Left
    8        11      30      1    1    0    0  ;   % Drift Right
    11       14      30      0    0    0    0  ;   % Intersection
    14       17      15      1    0    0    1  ;   % Obstacle
    17       22      30      1    1    1    1  ;   % Line Lost -> U-Turn
    22       25      30      1    0    0    1  ;   % Return
];
dt = 0.05;
t_end = scenario(end, 2);
t = (0 : dt : t_end)';
N = numel(t);

% 2. Build signals
dist_sig = zeros(N,1); L2_sig = ones(N,1); L1_sig = ones(N,1);
R1_sig = ones(N,1);   R2_sig = ones(N,1);
for k = 1 : size(scenario, 1)
    idx = t >= scenario(k,1) & t < scenario(k,2);
    dist_sig(idx) = scenario(k,3);
    L2_sig(idx)   = scenario(k,4);
    L1_sig(idx)   = scenario(k,5);
    R1_sig(idx)   = scenario(k,6);
    R2_sig(idx)   = scenario(k,7);
end

% Convert to timeseries
ts_dist = timeseries(dist_sig, t);
ts_L2   = timeseries(L2_sig,   t);
ts_L1   = timeseries(L1_sig,   t);
ts_R1   = timeseries(R1_sig,   t);
ts_R2   = timeseries(R2_sig,   t);
ts_time = timeseries(t, t); % Substitute for SimClock to ensure precision

% 3. Update model and reconnect
mdl = 'RobotSimulation';
if ~bdIsLoaded(mdl), load_system(mdl); end

% Replace blocks and reconnect wires immediately
% Order: Distance(1), L2(2), L1(3), R1(4), R2(5), Clock(6)
updateBlockAndLine(mdl, 'Distance_cm', 'ts_dist', 1);
updateBlockAndLine(mdl, 'L2',          'ts_L2',   2);
updateBlockAndLine(mdl, 'L1',          'ts_L1',   3);
updateBlockAndLine(mdl, 'R1',          'ts_R1',   4);
updateBlockAndLine(mdl, 'R2',          'ts_R2',   5);
updateBlockAndLine(mdl, 'SimClock',    'ts_time', 6);
save_system(mdl);

% 4. Run simulation and receive results in a single object called simOut
fprintf('Running simulation...\n');
simOut = sim(mdl, 'StopTime', num2str(t_end));
fprintf('✅ Simulation finished!\n');

% 5. Extract results for plotting
% We pull them from simOut to avoid "Unrecognized variable" errors
lPWM = simOut.leftPWM_out;
rPWM = simOut.rightPWM_out;
t_axis = (0:length(lPWM)-1)*dt;

% 6. Plotting
figure('Name','Advanced Robot Simulation Results','Color','w');

% --- First plot (Motors) ---
subplot(2,1,1);
set(gca, 'Color', 'k'); % Black background for the plot
hold on;
plot(t_axis, lPWM, 'c', 'LineWidth', 1.5); % Left motor in Cyan to be clearer
plot(t_axis, rPWM, 'r', 'LineWidth', 1.5); % Right motor in Red

% Customize colors for titles and axes (k = black)
title('Motor Outputs', 'Color', 'k', 'FontWeight', 'bold');
ylabel('PWM Speed', 'Color', 'k', 'FontWeight', 'bold');
set(gca, 'XColor', 'k', 'YColor', 'k'); % Axes line and label colors
legend('Left Motor','Right Motor', 'TextColor', 'k', 'Color', 'w'); % White legend background with black text
grid on;

% --- Second plot (Distance) ---
subplot(2,1,2);
set(gca, 'Color', 'k'); % Black background for the plot
hold on;

% Plot distance input in white
stairs(t, dist_sig, 'w', 'LineWidth', 1.5);

% Customize colors for titles and axes (k = black)
title('Distance Input (Obstacles)', 'Color', 'k', 'FontWeight', 'bold');
ylabel('Distance (cm)', 'Color', 'k', 'FontWeight', 'bold');
xlabel('Time (s)', 'Color', 'k', 'FontWeight', 'bold');
set(gca, 'XColor', 'k', 'YColor', 'k'); % Axes line and label colors
grid on;

% --- Helper function to update block and reconnect ---
function updateBlockAndLine(mdl, blkName, varName, portIdx)
    path = [mdl '/' blkName];
    pos = get_param(path, 'Position');
    
    % Delete old line if present to avoid overlap
    lines = get_param(path, 'PortHandles');
    lineArr = get_param(lines.Outport, 'Line');
    if lineArr ~= -1, delete_line(lineArr); end
    
    % Delete old block and add From Workspace
    delete_block(path);
    add_block('simulink/Sources/From Workspace', path, ...
        'VariableName', varName, 'Position', pos);
        
    % Most important step: Reconnect the wire to the Controller input
    add_line(mdl, [blkName '/1'], ['RobotController/' num2str(portIdx)], 'autorouting', 'on');
end
