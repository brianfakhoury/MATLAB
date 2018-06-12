function [FCNHNDL] = eyegame(varargin)
    %MATLABTETRIS A MATLAB version of the classic game Tetris.
    % Patch refers to one of the brick pieces
    rng('shuffle'); % This sets the internal seed generator, will need later.
    f_clr = [.341 .717 .42];  % Figure background color
    % Game window
    S.fig = figure(...
        'units','pixels',...
        'name','Tetris',...
        'menubar','none',...
        'visible','off',...
        'numbertitle','off',...
        'position',[200 100 650 720],... % When the window opens, these specify coordinates realtive
        ...                              % to the bottom left corner [x,y,width,height]
        'color',f_clr,... %
        ... % these settings bind our custom event functions
        'keypressfcn',@fig_kpfcn2,...
        'closereq',@fig_clsrqfcn,...
        'busyaction','cancel',...
        'windowbuttondownfcn', @fig_wbdfcn,...
        'resizefcn', @fig_rszfcn,...
        'renderer','opengl'... % This uses extra gpu resources if available
    );
    % Game tick
    S.tmr = timer(...
        'Name','Tetris_timer',...
        'Period',1,...
        'StartDelay',1,...
        'TasksToExecute',50,...
        'ExecutionMode','fixedrate',...
        'TimerFcn',@game_step...
    );
    % The main board
    S.axs = axes(...
        'units','pix',...
        'position',[145 60 360 630],...
        'ycolor',f_clr,...
        'xcolor',f_clr,...
        'xtick',[],...
        'ytick',[],...
        'xlim',[-1 11],...
        'ylim',[-1 20],...
        'color',f_clr,...
        'visible','off'...
    );
    % Template positions for the patch objects (bricks) in both axes.
    X = [
        0.0, 0.2, 0.0;
        0.2, 0.8, 0.2;
        0.2, 0.8, 0.8;
        0.8, 0.2, 0.8;
        1.0, 0.2, 1.0;
        0.0, 0.2, 1.0;
        0.0, 0.2, 0.0
    ];
    Y = [
        0.0, 0.2, 0.0;
        0.2, 0.2, 0.2;
        0.8, 0.8, 0.2;
        0.8, 0.8, 0.8;
        1.0, 0.2, 1.0;
        1.0, 0.2, 0.0;
        0.0, 0.2, 0.0
    ];
    g1 = repmat([.9 .65 .4],[1,1,3]); % Grey color used throughout.
    % Make the board boarders.
    for jj = [-1 10]
        Xi = X + jj;
        for ii = -1:19
            patch(Xi,Y+ii,g1,'edgecolor','none','handlevis','callback')
        end
    end
    for ii = 0:9
        patch(X+ii,Y-1,g1,'edgecolor','none','handlevis','callback')
    end

    % Patch color handles
    S.pch = zeros(10,20);

    for jj = 0:19 % Make the board squares.
        for ii = 0:9
                S.pch(ii+1,jj+1) = patch(X+ii,Y+jj,'w','edgecolor','w');
        end
    end
    % Hold the colors of the pieces, and board index where each first appears.
    S.PCHCLR = {reshape([1 .75 .5 0 0 0 0 0 0],1,3,3),...
                reshape([0 0 0 1 .75 .5 0 0 0],1,3,3),...
                reshape([0 0 0 0 0 0 1 .75 .5],1,3,3),...
                reshape([1 .75 .5 1 .75 .5 0 0 0],1,3,3),...
                reshape([1 .75 .5 0 0 0 1 .75 .5],1,3,3),...
                reshape([0 0 0 1 .75 .5 1 .75 .5],1,3,3),...
                reshape([.5 .25 0 .5 .25 0 .5 .25 0],1,3,3)}; % Piece colors.
    % S.PCHIDX holds the location where each piece first appears on the board.
    S.PCHIDX = {194:197,[184 185 186 195],[184 185 186 196],...
                [184 185 186 194],[194 195 185 186],[184 195 185 196],...
                [185 186 195 196]};

    S.tick = 0;

    S.CURPRV = []; % Holds current preview patches.
    S.PRVNUM = []; % Holds the preview piece number, 1-7.
    make_preview;  % Call the function which chooses the piece to go next.

    S.BRDMAT = false(10,20); % The matrix game board.
    S.CURROT = 1; % Holds the current rotation of the current piece.
    S.PNTVCT = [40 100 300 800]; % Holds the points per number of lines.
    S.CURLVL = 1; % The current level.
    S.CURLNS = 0; % The current number of lines
    S.STPTMR = 0; % Kills timer when user is pushing keyboard buttons.
    S.CURSCR = 0; % Holds the current score during play.
    S.PLRLVL = 1; % The level the player chooses to start...
    % These next two dictate how fast the game increases its speed and also how
    % many lines the player must score to go up a level, respectively.  The
    % first value shoould be on (0,1].  Smaller values increase speed faster.
    % No error handling is provided if you use bad values!
    S.LVLFAC = .750;  % Percent of previous timerdelay. 
    S.CHGLVL = 3; % Increment level every S.CHGLVL lines.
    
    S.SETBLK = @set_blocks; % allow public broadcasting of board state
    
    set(S.fig, 'visible','on');

    if nargin && isnumeric(varargin{1})
        S.PLRLVL = min(round(max(varargin{1},1)),9);  % Starting level.
    end

    function val = get_game_memory(varargin)
        val = S.(varargin{1});
    end
    FCNHNDL = @get_game_memory;
    
    pbt_call;
        
    
    function [] = make_preview(varargin)
    % This function chooses which piece is going next and displays it.
        if nargin
            S.PRVNUM = varargin{1};
        else
            S.PRVNUM = ceil(rand*7); % Randomly choose one of the pieces.
        end
    end


    function [] = pbt_call(varargin)
    % Initiate new game.
        set(S.pch(:),'facecol','w','edgecol','w'); % Clear board.
        ND = round(1000*S.LVLFAC^(S.PLRLVL-1))/1000;% Update Timer.
        set(S.tmr,'startdelay',ND,'period',ND);
        S.CURLNS = 0; % New Game -> start at zero.
        S.CURLVL = S.PLRLVL; % Set the level to players choice.
        S.CURSCR = 0; % New Game -> start at zero.
    end


    function [] = play_tet()
    % Picks a next piece and puts the preview in correct axes.
        S.PNM = S.PRVNUM; % Hold this for keypresfcn.
        S.CUR = S.PCHIDX{S.PRVNUM}; % Current loc. of current piece.
        S.COL = S.PCHCLR{S.PRVNUM}; % Transfer correct color.
        S.CURROT = 1; % And initial rotation number.
        set(S.pch(S.CUR),'facec','flat','cdata',S.COL,'edgecol','none')

        if any(S.BRDMAT(S.CUR))
            disp('....Game over....')
            clean_tet;  % Clean up the board.
            set(S.fig,'keypressfcn',@fig_kpfcn2)
            return
        else
            S.BRDMAT(S.CUR) = true; % Now update the matrix...
        end

        make_preview;  % Set up the next piece.
        start_tet;     % Start the timer.
    end


    function [] = game_step(varargin)
        % Timerfcn, advances the current piece down the board
        S.tick = S.tick + 1;
        if S.STPTMR && nargin  % Only timer calls with args...
            return  % So that timer can't interrupt FIG_KPFCN!
        end

        col = ceil(S.CUR/10); % S.CUR defined in play_tet.
        row = rem(S.CUR-1,10) + 1;  % These are for the board matrix.

        if any(col==1)  % Piece is at the bottom of the board.
            stop_tet;
            check_rows;
            play_tet;
        else
            ur = unique(row);  % Check to see if we can drop it down

            for kk = 1:length(ur)
                if (S.BRDMAT(ur(kk),min(col(row==ur(kk)))-1))
                    stop_tet;
                    check_rows;
                    play_tet;
                    return
                end
            end

            mover(-10)  % O.k. to drop the piece... do it.
        end
    end


    function [] = fig_kpfcn(varargin)
    % Figure (and pushbutton) keypressfcn
        S.STPTMR = 1;  % Stop timer interrupts.  See GAME_STEP

        if strcmp(varargin{2}.Key,'downarrow')
            game_step; % Just call another step.
            S.STPTMR = 0;  % Unblock the timer.
            return
        end

        col = ceil(S.CUR/10); % S.CUR defined in play_tet.
        row = rem(S.CUR-1,10) + 1;  % These index into board matrix.

        switch varargin{2}.Key
            case 'rightarrow'
                % Without this IF, the piece will wrap around!
                if max(row)<=9
                    uc = unique(col);  % Check if object to the right.

                    for kk = 1:length(uc)
                        if (S.BRDMAT(max(row(col==uc(kk)))+1,uc(kk)))
                            S.STPTMR = 0;
                            return
                        end
                    end

                    mover(1)   % O.k. to move.
                end
            case 'leftarrow'
                if min(row)>=2
                    uc = unique(col);  % Check if object to the left

                    for kk = 1:length(uc)
                        if (S.BRDMAT(min(row(col==uc(kk)))-1,uc(kk)))
                            S.STPTMR = 0;
                            return
                        end
                    end

                    mover(-1)  % O.k. to move.
                end
            case 'uparrow'
                if strcmp(varargin{2}.Modifier,'shift')
                    arg = 1;  % User wants counter-clockwise turn.
                else
                    arg = 0;
                end

                turner(row,col,arg);  % Turn the piece.
            case 'q'
                quit_check;  % User might want to quit the game.
            case 'n'
                restart_game;
            otherwise
        end

        S.STPTMR = 0;  % Unblock the timer.
    end


    function [] = fig_kpfcn2(varargin)
    % Callback handles the case when 's' or 'p' is pressed if 
    % the game is paused or at game start.
        if strcmp(varargin{2}.Key,'s')
            play_tet; % Initiate Gameplay.

        end
        if strcmp(varargin{2}.Key,'p')
            pbt_call;  % User wants to pause/unpause.
        end

        if strcmp(varargin{2}.Key,'q')
            quit_check;  % Perhaps user wants to quit.
        end
            
        if strcmp(varargin{2}.Key,'n')
            restart_game;  % Perhaps user wants to restart.
        end
    end


    function [] = mover(N)
    % Common task. Moves a piece on the board.
        S.BRDMAT(S.CUR) = false; % S.CUR, S.COL defined in play_tet.
        S.BRDMAT(S.CUR+N) = true; % All checks should be done already.
        S.CUR = S.CUR + N;
        set([S.pch(S.CUR-N),S.pch(S.CUR)],...
            {'facecolor'},{'w';'w';'w';'w';'flat';'flat';'flat';'flat'},...
            {'edgecolor'},{'w';'w';'w';'w';'none';'none';'none';'none'},...
            {'cdata'},{[];[];[];[];S.COL;S.COL;S.COL;S.COL})
    end


    function [] = turner(row,col,arg)
    % Common task. Rotates the pieces once at a time.
    % r is reading left/right, c is reading up/down.
    % For the switch:  1-I,2-T,3-L,4-J,5-Z,6-S,7-O
        switch S.PNM % Defined in play_tet.  Turn depends on shape.
            case 1  
                if any(col>19) || all(col<=2)
                    return
                else
                    if S.CURROT == 1
                        r = [row(2),row(2),row(2),row(2)];
                        c = [col(2)-2,col(2)-1,col(2),col(2)+1];
                        S.CURROT = 2;
                    elseif all(row>=9)
                        r = 7:10;
                        c = [col(2),col(2),col(2),col(2)];
                        S.CURROT = 1;
                    elseif all(row==1)
                        r = 1:4;
                        c = [col(2),col(2),col(2),col(2)];
                        S.CURROT = 1;
                    else
                        r = [row(2)-1,row(2),row(2)+1,row(2)+2];
                        c = [col(2),col(2),col(2),col(2)];
                        S.CURROT = 1;
                    end
                end
            case 2
                if sum(col==1)==3
                    return
                end

                if arg
                    S.CURROT = mod(S.CURROT+1,4)+1;
                end

                switch S.CURROT
                    case 1
                        r = [row(2),row(2),row(2),row(2)+1];
                        c = [col(2)-1,col(2),col(2)+1,col(2)];
                    case 2
                        if sum(row==1)==3
                            r = [1 2 3 2];
                            c = [col(2),col(2),col(2),col(2)-1];
                        else
                            r = [row(2)-1,row(2),row(2),row(2)+1];
                            c = [col(2),col(2),col(2)-1,col(2)];
                        end
                    case 3
                        r = [row(2)-1,row(2),row(2),row(2)];
                        c = [col(2),col(2),col(2)-1,col(2)+1];
                    case 4
                        if sum(row==10)==3
                            r = [9 9 8 10];
                            c = [col(2)+1,col(2),col(2),col(2)];
                        else
                            r = [row(2)-1,row(2),row(2),row(2)+1];
                            c = [col(2),col(2),col(2)+1,col(2)];
                        end
                end

                S.CURROT = mod(S.CURROT,4) + 1;
            case 3
                if sum(col==1)==3
                    return
                end

                if arg
                    S.CURROT = mod(S.CURROT+1,4)+1;
                end

                switch S.CURROT
                    case 1
                        r = [row(2),row(2),row(2),row(2)+1];
                        c = [col(2)+1,col(2),col(2)-1,col(2)-1];
                    case 2
                        if sum(row==1)==3
                            r = [1:3 1];
                            c = [col(2),col(2),col(2),col(2)-1];
                        else
                            r = [row(2)-1,row(2),row(2)-1,row(2)+1];
                            c = [col(2),col(2),col(2)-1,col(2)];
                        end
                    case 3
                        r = [row(2)-1,row(2),row(2),row(2)];
                        c = [col(2)+1,col(2),col(2)+1,col(2)-1];
                    case 4
                        if sum(row==10)==3
                            r = [10 9 10 8];
                            c = [col(2)+1,col(2),col(2),col(2)];
                        else
                            r = [row(2)-1,row(2),row(2)+1,row(2)+1];
                            c = [col(2),col(2),col(2),col(2)+1];
                        end
                end

                S.CURROT = mod(S.CURROT,4) + 1;
            case 4
                if sum(col==1)==3
                    return
                end

                if arg
                    S.CURROT = mod(S.CURROT+1,4)+1;
                end

                switch S.CURROT
                    case 1
                        r = [row(2),row(2),row(2),row(2)+1];
                        c = [col(2)-1,col(2),col(2)+1,col(2)+1];
                    case 2
                        if sum(row==1)==3
                            r = [1 2 3 3];
                            c = [col(2),col(2),col(2),col(2)-1];
                        else
                            r = [row(2)-1,row(2),row(2)+1,row(2)+1];
                            c = [col(2),col(2),col(2),col(2)-1];
                        end
                    case 3
                        r = [row(2)-1,row(2),row(2),row(2)];
                        c = [col(2)-1,col(2),col(2)-1,col(2)+1];
                    case 4
                        if sum(row==10)==3
                            r = [8 9 8 10];
                            c = [col(2)+1,col(2),col(2),col(2)];
                        else
                            r = [row(2)-1,row(2),row(2)-1,row(2)+1];
                            c = [col(2),col(2),col(2)+1,col(2)];
                        end
                end

                S.CURROT = mod(S.CURROT,4) + 1;
            case 5
                if any(col(2)>19) || sum(col==1)==2
                    return
                elseif S.CURROT==1;
                    r = [row(2),row(2),row(2)-1,row(2)-1];
                    c = [col(2)+1,col(2),col(2),col(2)-1];
                    S.CURROT = 2;
                else
                    if sum(row==10)==2
                        r = [10 9 9 8];
                        c = [col(2)-1,col(2)-1,col(2),col(2)];
                    else
                        r = [row(2)-1,row(2),row(2),row(2)+1];
                        c = [col(2),col(2),col(2)-1,col(2)-1];
                    end

                    S.CURROT = 1;
                end
            case 6
                if any(col(2)>19)|| sum(col==1)==2
                    return
                elseif S.CURROT==1;
                    r = [row(2)+1,row(2),row(2)+1,row(2)];
                    c = [col(2)-1,col(2),col(2),col(2)+1];
                    S.CURROT = 2;
                else
                    if sum(row==1)==2
                        r = [1 2 2 3];
                        c = [col(2)-1,col(2)-1,col(2),col(2)];
                    else
                        r = [row(2)-1,row(2),row(2),row(2)+1];
                        c = [col(2)-1,col(2),col(2)-1,col(2)];
                    end
                    S.CURROT = 1;
                end
            otherwise
                return % The O piece.
        end

        ind = r + (c-1)*10; % Holds new piece locations.
        tmp = S.CUR; % Want to call SET last! S.CUR defined in play_tet.
        S.BRDMAT(S.CUR) = false;

        if any(S.BRDMAT(ind)) % Check if any pieces are in the way.
            S.BRDMAT(S.CUR) = true;
            return
        end

        S.BRDMAT(ind) = true;
        S.CUR = ind; % S.CUR, S.COL defined in play_tet.
        set([S.pch(tmp),S.pch(ind)],...
            {'facecolor'},{'w';'w';'w';'w';'flat';'flat';'flat';'flat'},...
            {'edgecolor'},{'w';'w';'w';'w';'none';'none';'none';'none'},...
            {'cdata'},{[];[];[];[];S.COL;S.COL;S.COL;S.COL});
    end


    function [] = check_rows()
    % Checks if any row(s) needs clearing and clears it (them).
        TF = all(S.BRDMAT); % Finds the rows that are full.

        if any(TF)  % There is a row that needs clearing.
            sm = sum(TF); % How many rows are there?
            B = false(size(S.BRDMAT));  % Temp store to switcheroo.
            B(:,1:20-sm) = S.BRDMAT(:,~TF);
            S.BRDMAT = B;
            TF1 = find(TF); % We only need to drop those rows above.
            L = length(TF1);
            TF = TF1-(0:L-1);
            S.CURLNS = S.CURLNS + L;
            S.CURSCR = S.CURSCR+S.PNTVCT(L)*S.CURLVL;

            for kk = 1:L % Make these rows to flash for effect.
                set(S.pch(:,TF1(:)),'facecolor','r');
                pause(.1)
                set(S.pch(:,TF1(:)),'facecolor','g');
                pause(.1)
            end

            for kk = 1:L % 'Delete' these rows.
                set(S.pch(:,TF(kk):19),...
                    {'facecolor';'edgecolor';'cdata'},...
                    get(S.pch(:,TF(kk)+1:20),...
                    {'facecolor';'edgecolor';'cdata'}));
            end

            if (floor(S.CURLNS/S.CHGLVL)+1)>S.CURLVL % Level display check.
                S.CURLVL = S.CURLVL + 1;
                ND = round(get(S.tmr,'startdelay')*S.LVLFAC*1000)/1000;
                ND = max(ND,.001);
                set(S.tmr,'startdelay',ND,'period',ND) % Update timer
            end


        end
    end


    function [] = clean_tet()
    % Cleans up the board and board matrix after Game Over.
        for kk = 1:20
            set(S.pch(:,kk),'cdata',g1,'edgecol','none')
        end
        stop_tet;  % Stop the timer.
        S.BRDMAT(:) = false; % Reset the board matrix.
    end


    function [] = start_tet()
    % Sets the correct callbacks and timer for a new game
        set([S.fig],'keypressfcn',@fig_kpfcn)
        start(S.tmr)
    end


    function [] = stop_tet()
    % Sets the correct callbacks and timer to stop game
        stop(S.tmr)
        set([S.fig],'keypressfcn','fprintf('''')')
    end


    function [] = fig_clsrqfcn(varargin)
    % Clean-up if user closes figure while timer is running.
        try  % Try here so user can close after error in creation of GUI.
            warning('off','MATLAB:timer:deleterunning')
            delete(S.tmr)  % We always want the timer destroyed first.
            warning('on','MATLAB:timer:deleterunning')
        catch
        end
        delete(varargin{1})  % Now we can close it down.
    end


    function [] = fig_wbdfcn(varargin)
    % The WindowButtonDownFcn for the figure.
    % In here user wants to select a starting level.
        tmp = inputdlg('Enter Starting Level',...
                       'Level',1,{sprintf('%i',S.PLRLVL)});

        if ~isempty(tmp)  % User might have closed dialog.           
            S.PLRLVL = min(round(max(str2double(tmp),1)),9);
        end
    end


    function [] = fig_rszfcn(varargin)
    % The figure's resizefcn
        pos = get(S.fig,'pos');  % Don't allow distorted shapes...
        set(S.fig,'pos',[pos(1) pos(2) pos(3), pos(4)]);
        hgt = pos(4) * 650/720;
        wd = hgt * 360 / 630;
        set(S.axs,'pos', [pos(3)/2-wd/2 pos(4)/2-hgt/2 wd hgt]);
    end


    function [] = quit_check()
    % Creates a dialog box to check if the user wants to quit.
        QG = questdlg('End current game?','Yes', 'No');
        if strcmp(QG,'Yes')
            clean_tet;
            close(S.fig);
        end
    end

    function [] = restart_game()
    % reset game and gameboard
        QG = questdlg('Restart game?','Yes', 'No');
        if strcmp(QG,'Yes')
            clean_tet;
            pbt_call;
            set(S.fig,'keypressfcn',@fig_kpfcn2)
        end
    end

    function [] = set_blocks(BRD)
        % Set specific blocks to design board
        if isequal(size(BRD), size(S.BRDMAT)) || (isvector(BRD) && isvector(S.BRDMAT) && numel(BRD) == numel(S.BRDMAT))
            brdsize = size(BRD);
            for x=1:brdsize(1)
                for y=1:brdsize(2)
                    S.BRDMAT(x,y) = BRD(x,y);
                    if BRD(x,y)>0
                        set(S.pch(x,y),'facecol','b','edgecol','g');
                    end
                end
            end
            
        end
    end
        
end