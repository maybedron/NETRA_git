function build_district_sim()
P = struct('lambda_day',200,'nServers',2,'svcMean',10,'aiTime',1,'days',30, ...
    'clinicMin',480,'acc',0.827,'prior',[0.493 0.101 0.273 0.053 0.081]);
lib = 'sldelib'; load_system(lib);
m = 'netra_dist'; if bdIsLoaded(m), close_system(m,0); end
new_system(m); open_system(m);
set_param(m,'StopTime',num2str(P.days*P.clinicMin),'SolverType','Variable-step');

% AI referral rate and referred-grade mix (Monte Carlo, +/-1 error model)
rng(1); n = 1e6;
tg = min(sum(rand(n,1) > cumsum(P.prior),2),4);
pg = tg; wr = rand(n,1) > P.acc; st = sign(rand(n,1)-0.5); st(st==0)=1;
pg(wr) = tg(wr) + st(wr); pg = min(max(pg,0),4);
pRef = mean(pg>=2);
cond = arrayfun(@(g) mean(pg(pg>=2)==g), 2:4); cdf = cumsum(cond);
fprintf('Referral fraction (AI predicted grade>=2): %.3f\n', pRef);

iaA  = sprintf('dt = -log(rand)*%g;', P.clinicMin/P.lambda_day);
iaB  = sprintf('dt = -log(rand)*%g;', P.clinicMin/(P.lambda_day*pRef));
gact = sprintf('u=rand; g=2+(u>%g)+(u>%g); entity.Grade=g+1;', cdf(1), cdf(2));
sact = sprintf('dt = -log(rand)*%g;', P.svcMean);

% ---------- Scenario A: Generator -> FIFO Queue -> Servers -> Terminator
y = 0;
gA = mk(m,lib,'Entity Generator','A_gen',y);
setp(gA,'TimeSource','MATLAB action'); setp(gA,'IntergenerationTimeAction',iaA);
qA = mk(m,lib,'Entity Queue','A_queue',y); setp(qA,'QueueType','FIFO'); setp(qA,'Capacity','1e6');
setp(qA,'NumberEntitiesInBlock','on'); setp(qA,'AverageWait','on');
sA = mk(m,lib,'Entity Server','A_servers',y); setp(sA,'Capacity',num2str(P.nServers));
setp(sA,'ServiceTimeSource','MATLAB action'); setp(sA,'ServiceTimeAction',sact);
tA = mk(m,lib,'Entity Terminator','A_sink',y);
ln(gA,1,qA,1); ln(qA,1,sA,1); ln(sA,1,tA,1);
logq(m,qA,'A');

% ---------- Scenario B: Generator(referred only) -> AI delay -> Priority Queue -> Servers -> Terminator
y = 300;
gB = mk(m,lib,'Entity Generator','B_gen',y);
setp(gB,'TimeSource','MATLAB action'); setp(gB,'IntergenerationTimeAction',iaB);
setp(gB,'EntityTypeName','PatientB'); setp(gB,'AttributeName','Grade'); setp(gB,'GenerateAction',gact);
ai = mk(m,lib,'Entity Server','B_AI',y); setp(ai,'Capacity','1000');
setp(ai,'ServiceTimeSource','Dialog'); setp(ai,'ServiceTimeValue',num2str(P.aiTime));
qB = mk(m,lib,'Entity Queue','B_queue',y); setp(qB,'QueueType','Priority');
setp(qB,'PrioritySource','Grade'); setp(qB,'SortingDirection','Descending');
setp(qB,'Capacity','1e6'); setp(qB,'NumberEntitiesInBlock','on'); setp(qB,'AverageWait','on');
sB = mk(m,lib,'Entity Server','B_servers',y); setp(sB,'Capacity',num2str(P.nServers));
setp(sB,'ServiceTimeSource','MATLAB action'); setp(sB,'ServiceTimeAction',sact);
tB = mk(m,lib,'Entity Terminator','B_sink',y);
ln(gB,1,ai,1); ln(ai,1,qB,1); ln(qB,1,sB,1); ln(sB,1,tB,1);
logq(m,qB,'B');

Simulink.BlockDiagram.arrangeSystem(m);
save_system(m, fullfile(pwd,'netra_dist.slx'));
disp('Saved netra_dist.slx. Check for FAIL lines above.');
end

function b = mk(m,lib,src,name,y)
b = [m '/' name]; add_block([lib '/' src], b, 'Position',[30 y+30 130 y+80]);
end
function setp(b,p,v)
try, set_param(b,p,v);
catch e
    fprintf('FAIL %s.%s = %s\n  %s\n', get_param(b,'Name'), p, v, strtok(e.message,newline));
end
end
function h = eo(b)
% entity output port = rightmost outport (statistics ports sit on top)
ph = get_param(b,'PortHandles'); o = ph.Outport; h = o(1);
if numel(o) > 1
    x = zeros(1,numel(o));
    for k = 1:numel(o), p = get_param(o(k),'Position'); x(k) = p(1); end
    [~,k] = max(x); h = o(k);
end
end
function ln(a,~,b,j)
pb = get_param(b,'PortHandles');
try, add_line(get_param(a,'Parent'), eo(a), pb.Inport(j));
catch e, fprintf('LINE FAIL %s -> %s  %s\n', get_param(a,'Name'),get_param(b,'Name'),strtok(e.message,newline)); end
end
function logq(m,q,tag)
ph = get_param(q,'PortHandles'); o = ph.Outport; he = eo(q); o = o(o ~= he);
for k = 1:numel(o)
    w = [m '/' tag '_stat' num2str(k)];
    add_block('simulink/Sinks/To Workspace', w, 'VariableName',[tag '_stat' num2str(k)], 'SaveFormat','Timeseries');
    pw = get_param(w,'PortHandles'); add_line(m, o(k), pw.Inport(1));
end
end
