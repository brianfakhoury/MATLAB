% On Center/ Off Surround Neural Model.
% Built with MatLab 2019a 9.6.0.1072779
% Framerate on Late 2016 MacBook Pro i7: ~60fps

% Usage:
% 
% Move mouse over input box to show input. Click to 
% flash input on and off. Press 'q' to close and quit.
%

% Model Parameters
A = 1;
B = 1;
C = 1;
D = 1;
dt = 0.1;
Gex = fspecial('gaussian', [3 3], 1);
Ginh = fspecial('gaussian', [8 8], 3);
Gex2 = fspecial('gaussian', [6 6], 2);
Ginh2 = fspecial('gaussian', [16 16], 4);

% GUI/Control Paramsq

opengl hardware

% Figure Setup
h = figure('DefaultAxesFontSize', 24, 'Position', [200 500 1000 250]);
set(gcf, 'WindowButtonMotionFcn', @updatePoint);
set(gcf,'WindowButtonDown',@clickfn)
set(gcf,'WindowButtonUp',@clickfn)
set(gcf,'WindowKeyPressFcn',@esckey);
set(0, 'DefaultFigureRenderer', 'opengl');

h.UserData = struct('xval', -1, 'yval', -1, 'click', false, 'running', true, 'tx', 0);

% Neurons State
prev1 = zeros(50,50);
curr1 = zeros(50,50);
prev2 = zeros(50,50);
curr2 = zeros(50,50);
I = zeros(50,50);

% Axes setup
subplot(1,4,1) % plot 1
input_surface = surface(I);
colormap(gca, 'gray')
caxis([0 1])
shading flat
axis off;
h.UserData.tx = gca;
subplot(1,4,2) % plot 2
out1_surface = surface(curr1);
colormap(gca, 'jet')
axis off;
shading interp;
caxis([-0.1 0.1])
subplot(1,4,3) % plot 3
out2_surface = surface(curr2);
colormap(gca, 'jet')
axis off;
shading interp;
caxis([-0.05 0.05])
subplot(1,4,4) % plot 4
out3_surface = surface(zeros(50,50));
colormap(gca, 'jet')
axis off;
shading interp;
caxis([-0.02 0.02])


% Main Loop
frame_count = 0;
time_tot = 0;
frame_rate = 0;
while h.UserData.running
    tic
    I = buildSquareInput(h);
    input_surface.CData = I;
    curr1 = prev1 + dt*(-A*prev1 + (B-prev1).*conv2(I+D*curr2, Gex, 'same') - (C + prev1) .* conv2(I+D*curr2,Ginh, 'same'));
    out1_surface.CData = curr1;
    curr2 = prev2 + dt*(-A*prev2 + (B-prev2).*conv2(curr1, Gex2, 'same') - (C + prev2) .* conv2(curr1,Ginh2, 'same'));
    out2_surface.CData = curr2;
    out3_surface.CData = curr1 - prev1;
    drawnow
    prev1 = curr1;
    prev2 = curr2;
    a = toc;
    frame_count = frame_count + 1;
    time_tot = time_tot + a;
    if time_tot > 1
        frame_rate = frame_count / time_tot;
        frame_count = 0;
        time_tot = 0;
        disp(['Frame rate: ' num2str(frame_rate)])
    end
end
close(h);

% Input builders
function input = buildLineInput(h)
    input = zeros(50,50);
    if h.UserData.xval ~= -1 && h.UserData.yval ~= -1
        for i=h.UserData.yval:h.UserData.yval+19
            if i<=50
                input(h.UserData.xval,i) = 0.5;
            else
                break;
            end
        end
    end
end

function input = buildSquareInput(h)
    input = zeros(50,50);
    if h.UserData.xval ~= -1 && h.UserData.yval ~= -1
        for i=h.UserData.xval:h.UserData.xval+9
            if i<=50
                for j=h.UserData.yval:h.UserData.yval+9
                    if j<=50
                        input(i,j) = 0.5;
                    else
                        break
                    end
                end
            else
                break
            end
        end
    end
end

% Callbacks
function updatePoint(h,~)
    point = get(h.UserData.tx,'CurrentPoint');
    tyval = floor(point(1,1));
    txval = floor(point(1,2));
    if txval < 0 || tyval < 0 || txval > 50 || tyval > 50 || h.UserData.click
        h.UserData.xval = -1;
        h.UserData.yval = -1;
    else
        h.UserData.yval = tyval + 1;
        h.UserData.xval = txval + 1;
    end
end

function clickfn(h,e)
    h.UserData.click = ~h.UserData.click;
    updatePoint(h, e);
end

function esckey(h,e)
    if e.Key == 'q'
        h.UserData.running = false;
    end
end