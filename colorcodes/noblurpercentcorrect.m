%rng(now) % DEBUGGING COMMENT THIS OUT FOR REAL EXPERIMENT
% this line sets the random number generator, if it's commented out then
% the random number generator is seeded by the clock and each time it runs
% we will a different assortment of images.

addpath(genpath('/usr/share/psychtoolbox-3'));
Screen('Preference', 'Verbosity', 0);
Screen('Preference', 'SkipSyncTests',2);
oldEnableFlag = Screen('Preference', 'SuppressAllWarnings', 1);

escapeKey = KbName('ESCAPE');
KbName('UnifyKeyNames');

expDir = '/home/finelab/Documents/code/ColorBlur';
cd(expDir);

plotit = 1; % DEBUGGING if 1 then will plot data
testflag = 0; % DEBUGGING = 1, 0 to run an experiment

if testflag
    savefilename = fullfile(expDir, 'data',  'test'); % this line when debugging
else
    titleText = 'Type your initials';
    sub_init = upper(inputdlg(titleText, titleText, [1, length(titleText)+10]));
    dateval = datestr(datetime('now'), 30);
    savefilename = fullfile(expDir, 'data',  [sub_init{1}, '_', dateval]); % this line for real data collection
end

ListenChar(2);

%% make beeps
InitializePsychSound;
pahandle = PsychPortAudio('Open');
nrchannels = 2;
beepHigh = MakeBeep(700,.2) * 0.1; beepHigh = [beepHigh; beepHigh];
beepLow  = MakeBeep(300,.2) * 0.1; beepLow  = [beepLow; beepLow];

backlum = 0; % background luminance of the screen
textSize = 40;

if strcmp(computer, 'PCWIN64')
    imgDir = 'Z:\viscog\FineLab\Nil_Color';
elseif strcmp(computer, 'GLNXA64')
    imgDir = 'AllImages';
end

T = readtable('object_metafile_runme.xlsx');
T = T(:, 1:5);
T.Properties.VariableNames = {'idnum'	,'objstyle',	'name',	'name_exist'	,'name_notexist'};

nImages = size(T, 1);

% ---- ONLY D=0 (no blur) ----
diopter_List = 0; %[0 1 2 3 4 5 6 7 8]; % diopter blurring to be included % DEBUGGING

imageUptime = 2.5; % how long the image is presented for
trial_struct = {NaN NaN NaN NaN NaN};
imgOrder = randperm(nImages);

nTrialsPerCond = floor(nImages/(length(diopter_List)*4));

ct = 1;
for n = 1:nTrialsPerCond
    for d = 1:length(diopter_List)
        for c = 1:4
            % 1. image num
            % 2. image name
            % 3. diopter level of blur
            % 4. object absent/present
            % 5. no color vs color
            TS(ct).idnum = T.idnum(imgOrder(ct));
            TS(ct).objstyle = T.objstyle(imgOrder(ct));
            TS(ct).object = mod(ct, 2)==0;
            if TS(ct).objstyle == 0 % non Adobe images
                TS(ct).name = T.name{imgOrder(ct)};
                TS(ct).name_exist = 'no name';
                TS(ct).name_notexist = 'no name';
            else % adobe
                if TS(ct).object == 1
                    TS(ct).name = T.name_exist{imgOrder(ct)};
                else
                    TS(ct).name = T.name_notexist{imgOrder(ct)};
                end
                TS(ct).name_exist = T.name_exist{imgOrder(ct)};
                TS(ct).name_notexist = T.name_notexist{imgOrder(ct)};
            end
            TS(ct).diopter = diopter_List(d);
            TS(ct).color = mod(ct, 4)>1;  % deciding which trials color (1) and which grayscale (0)
            TS(ct).correct = NaN;
            TS(ct).rt = NaN;
            TS(ct).resp = NaN;
            ct = ct+1;
        end
    end
end

% so now we have randomly assigned images to different conditions, but we
% still need to scramble what order they are presented in
trialOrder = randperm(size(TS, 2));

%% run it
[w, w_rect] = PsychImaging('OpenWindow',0,backlum);
pause(.5);

for t = 1:length(trialOrder) % 1:4 DEBUGGING
    mask = rand(26, 40);
    trl = trialOrder(t);
    if TS(trl).objstyle == 0 % non-Adobe
        if TS(trl).color == 0 && TS(trl).object == 0 % object absent / grayscale
            d = dir([imgDir, filesep,'img_', num2str(TS(trl).idnum) filesep, 'gray blurs', filesep,'*L_*Gray_D_', num2str(TS(trl).diopter * 10),'.png']);
            % diopter multiplied by 10 so don't have decimal points in the filename
        elseif TS(trl).color == 0 && TS(trl).object == 1 % object present / grayscale
            d = dir([imgDir, filesep,'img_', num2str(TS(trl).idnum) filesep, 'gray blurs', filesep, '*E_*Gray_D_', num2str(TS(trl).diopter * 10),'.png']);
        elseif TS(trl).color == 1 && TS(trl).object == 0 % object absent / color
            d = dir([imgDir, filesep,'img_', num2str(TS(trl).idnum) filesep, 'color blurs', filesep, '*L_*Color_D_', num2str(TS(trl).diopter * 10),'.png']);
        else
            d = dir([imgDir, filesep,'img_', num2str(TS(trl).idnum) filesep, 'color blurs', filesep, '*E_*Color_D_', num2str(TS(trl).diopter * 10),'.png']);
        end
    else % Adobe
        if TS(trl).color == 0
            d = dir([imgDir, filesep,'img_', num2str(TS(trl).idnum) filesep, 'gray blurs', filesep,'*A_*Gray_D_', num2str(TS(trl).diopter * 10),'.png']);
        else
            d = dir([imgDir, filesep,'img_', num2str(TS(trl).idnum) filesep, 'color blurs', filesep, '*A_*Color_D_', num2str(TS(trl).diopter * 10),'.png']);
        end
    end
    DATA(t) = TS(trl);

    % load the image
    try
        img = imread([d.folder,filesep,d.name]);
    catch
        ListenChar(0);
        Screen('CloseAll');
        save([savefilename, '_ABORT'], 'DATA');
        PsychPortAudio('Stop', pahandle);
        PsychPortAudio('Close', pahandle);
        return
    end
    while KbCheck; end % Wait until all keys are released.
    if t==1
        tmp = size(img, 2)/size(img, 1)*w_rect(4); % calculate the offset
        offset(1) = floor((w_rect(3)-tmp)/2);
        offset(2) = floor(offset(1)+tmp);
        backPtr=Screen('MakeTexture', w, backlum+zeros(size(img)),[],[],2);
        Screen('DrawTexture', w, backPtr);
        Screen('Flip', w);
    end
    %% put up text
    try
        Screen('DrawTexture', w, backPtr, [0 0 size(img, 2) size(img,1)], [ offset(1) 0 offset(2) w_rect(4)]);
        Screen('Flip', w);
        tic
        while toc<0.2
            ;
        end
        Screen('TextSize', w, 40);
        Screen('DrawTexture', w, backPtr, [0 0 size(img, 2) size(img,1)], [ offset(1) 0 offset(2) w_rect(4)]);
        DrawFormattedText(w, TS(trl).name, 960-round(length(TS(trl).name)*textSize/4), 500,[255 255 255]);
        Screen('Flip', w);
        tic
        while toc<1
            ;
        end
    catch
        Screen('CloseAll'); clear mex
    end

    imgPtr=Screen('MakeTexture', w, double(img)./255,[],[],2);
    Screen('DrawTexture', w, imgPtr, [0 0 size(img, 2) size(img,1)], [ offset(1) 0 offset(2) w_rect(4)]);
    Screen('Flip', w);
    startSecs = GetSecs;

    goodresp = 0; tic
    DATA(t).resp = NaN;
    DATA(t).correct = 0;
    DATA(t).rt = NaN;
    while goodresp == 0
        % Check the state of the keyboard.
        [ keyIsDown, respSecs, keyCode ] = KbCheck;

        if toc > imageUptime
            maskPtr=Screen('MakeTexture', w, mask,[],[],2);
            Screen('DrawTexture', w, maskPtr, [0 0 size(mask, 2) size(mask,1)], [ offset(1) 0 offset(2) w_rect(4)], [], 0);
            Screen('Flip', w);
        end

        % If the user is pressing a key, then display its code number and name.
        if keyIsDown
            keyCode = find(keyCode, 1);
            if strcmp(KbName(keyCode), 'j') && TS(trl).object==1
                DATA(t).resp = 1;
                DATA(t).correct = 1;
                PsychPortAudio('FillBuffer', pahandle, beepHigh);
                PsychPortAudio('Start', pahandle, 1, 0, 1);
                DATA(t).rt = respSecs-startSecs;
                goodresp = 1;
            elseif strcmp(KbName(keyCode), 'j') && TS(trl).object==0
                DATA(t).resp = 1;
                DATA(t).correct = 0;
                PsychPortAudio('FillBuffer', pahandle, beepLow);
                PsychPortAudio('Start', pahandle, 1, 0, 1);
                DATA(t).rt = respSecs-startSecs;
                goodresp = 1;
            elseif strcmp(KbName(keyCode), 'f') && TS(trl).object==1
                DATA(t).resp = 0;
                DATA(t).correct = 0;
                PsychPortAudio('FillBuffer', pahandle, beepLow);
                PsychPortAudio('Start', pahandle, 1, 0, 1);
                DATA(t).rt = respSecs-startSecs;
                goodresp = 1;
            elseif strcmp(KbName(keyCode), 'f') && TS(trl).object==0
                DATA(t).correct = 1;
                DATA(t).resp = 0;
                PsychPortAudio('FillBuffer', pahandle, beepHigh);
                PsychPortAudio('Start', pahandle, 1, 0, 1);
                DATA(t).rt = respSecs-startSecs;
                goodresp = 1;
            elseif keyCode == escapeKey
                ListenChar(0);
                Screen('Close',w);
                save([savefilename, '_ABORT'], 'DATA');
                PsychPortAudio('Stop', pahandle);
                PsychPortAudio('Close', pahandle);
                return;
            end
            if testflag
                save(savefilename, 'DATA', 'TS');
            end
            clear keyCode
            KbReleaseWait;
        end
    end

    Screen('DrawTexture', w, backPtr, [0 0 size(img, 2) size(img,1)], [ offset(1) 0 offset(2) w_rect(4)]);
    Screen('Flip', w);
    save(savefilename, 'DATA', 'diopter_List');
    pause(.3);
end

%%% ===================== NEW BLOCK START ===================== %%%
%%% SUMMARY & INCORRECT-TRIAL LISTING %%%
allCorrect = [DATA.correct] == 1;

fprintf('\n=== Accuracy summary ===\n');
if isempty(allCorrect)
    fprintf('No trials recorded.\n');
else
    fprintf('Overall %% correct: %.1f%%  (%d/%d)\n', 100*mean(allCorrect), sum(allCorrect), numel(allCorrect));
end

% Per-diopter (works even if there’s only D=0)
uds = unique([DATA.diopter]);
for d = uds
    idx = [DATA.diopter] == d;
    pc  = mean([DATA(idx).correct] == 1);
    fprintf('D_%d: %.1f%%  (%d/%d)\n', d, 100*pc, sum([DATA(idx).correct]==1), sum(idx));
end

% Optional: breakdowns by color / object for each incorrect trial
fprintf('\n=== Incorrect trials ===\n');
incIdx = find([DATA.correct] == 0);
if isempty(incIdx)
    fprintf('None 🎉\n');
else
    for k = incIdx(:).'
        d = DATA(k);
        if d.color==1, colStr = 'COLOR'; else, colStr = 'GRAY'; end
        if d.object==1, objStr = 'PRESENT'; else, objStr = 'ABSENT'; end
        fprintf('Trial %3d | img_%d | "%s" | D_%d | %s | %s | resp:%d | rt=%.3fs\n', ...
            k, d.idnum, d.name, d.diopter, colStr, objStr, d.resp, d.rt);
    end
end
fprintf('=================================\n\n');
%%% ====================== NEW BLOCK END ====================== %%%

% Stop playback:
PsychPortAudio('Stop', pahandle);
PsychPortAudio('Close', pahandle);

ListenChar(0);
Screen('Close',w);
addpath(genpath(pwd))

% Note: with only one diopter (0), this condition is false and plotting is skipped.
% If you still want to plot, change >1 to >=1 or use ~isempty(DATA).
if length(unique([DATA(:).diopter]))>1
    plotColorData;
end

return
