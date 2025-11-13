% color_blur_analysis_combine_subjects.m

d = dir('participant data/*.mat');

DATA = [];

% loop through the subjects
for subNum = 1:length(d)
    tmp = load(['participant data/',d(subNum).name]);
    DATA = [DATA;tmp.DATA];
end
    diopter_List = tmp.diopter_List;

% pull out the values into vectors
diopters = [DATA(:).diopter];
correct = [DATA(:).correct];
color = [DATA(:).color];
rts = [DATA(:).rt];

% summary statistics
nDiopters =8;
n = zeros(nDiopters,2);
c = zeros(nDiopters,2);
rt.mean = zeros(nDiopters,2);
rt.sem = zeros(nDiopters,2);
rt.mean_correct = zeros(nDiopters,2);

for i=1:length(diopter_List)
    for j=1:2   % color
        % find the trials for this blur and color
        id = diopters == diopter_List(i) & color ==j-1;% (diopters == diopter_List(i*2-1) |diopters == diopter_List(i*2))  & color == j-1;
        c(i,j) = sum(correct(id));
        n(i,j) = sum(id);
        rt.mean(i,j)= mean(rts(id));
        rt.mean_correct(i,j) = mean(rts(id & correct));
        rt.sem(i,j) = std(rts(id))/sqrt(n(i,j));
    end
end

% percent correct
pc = c./n;

x = [0:8];
plotX = {'1-2','3-4','5-6','7-8'};
colList = {'k','r'}; % color list (BW, Color)

% plot percent correct

figure(1)
clf
subplot(2,1,1)
hold on
for i=1:2
h=plot(x,100*pc(:,i),'ko-','MarkerFaceColor',colList{i});
end
xlabel('Blur (diopters)')
ylabel('Percent Correct')
legend({'BW','Color'})
set(gca,'XTick',x)
% set(gca,'XTickLabel',plotX)
ylim([0,100])
set(gca,'XLim',[-.25,8.25])
set(gca,'YLim',[38,100])
grid
%  plot mean and sem RT

clear h
subplot(2,1,2)
hold on
for i=1:2
errorbar(x+(i-1.5)*.05,rt.mean(:,i),rt.sem,'LineStyle','none','Color','k')

h(i)=plot(x+(i-1.5)*.05,rt.mean(:,i),'ko-','MarkerFaceColor',colList{i});
end
set(gca,'XTick',x)

%set(gca,'XTickLabel',plotX)

xlabel('Blur (diopters)')
ylabel('RT (s)')
legend(h,{'BW','Color'})
set(gca,'XLim',[-.25,8.25])

grid
return

%% combining speed and accuracy

% looks messy right now without much data

% from Heinrich René Liesefeld1 & Markus Janczyk, Behavior Research
% Methods, 2019:
% The most often suggested combined measure is the inverse
% efficiency score (IES; Townsend & Ashby, 1983), which is
% typically defined as mean correct RTs divided by PCs (Akhtar
% & Enns, 1989; Bruyer & Brysbaert, 2011):

IES = rt.mean_correct./pc;


figure(3)
clf

plot(x,IES,'o-');
hold on
xlabel('Diopter')
ylabel('IES')
legend({'BW','color'})
