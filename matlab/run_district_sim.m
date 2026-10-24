function R = run_district_sim(P)
% Scenario A (FIFO) vs B (AI triage + priority). Time unit: clinic-minutes.
if nargin < 1, P = struct(); end
d = struct('lambda_day',200, 'nServers',2, 'svcMean',10, 'aiTime',1, ...
    'days',30, 'clinicMin',480, 'acc',0.827, ...
    'prior',[0.493 0.101 0.273 0.053 0.081], ...   % APTOS class mix (ASSUMPTION)
    'refThresh',2, 'seed',42, 'nRuns',20);
f = fieldnames(d);
for i = 1:numel(f), if ~isfield(P,f{i}), P.(f{i}) = d.(f{i}); end, end

R.P = P;  runs = cell(P.nRuns,1);
for r = 1:P.nRuns
    rng(P.seed + r);
    T = P.days * P.clinicMin;
    mu = P.lambda_day * P.days;
    n = max(0, round(mu + sqrt(mu)*randn));            % Poisson count (normal approx)
    arr = sort(rand(n,1) * T);
    tg  = sum(rand(n,1) > cumsum(P.prior(:))', 2);     % true grade 0-4
    tg  = min(tg,4);
    pg  = tg;                                          % AI grade
    wrong = rand(n,1) > P.acc;
    step  = sign(rand(n,1) - 0.5); step(step==0) = 1;
    pg(wrong) = tg(wrong) + step(wrong);
    pg = min(max(pg,0),4);
    svc = -P.svcMean * log(rand(n,1));                 % exponential service

    sA = serve(arr, svc, zeros(n,1), P.nServers);
    ref = pg >= P.refThresh;
    sB = nan(n,1);
    sB(ref) = serve(arr(ref) + P.aiTime, svc(ref), pg(ref), P.nServers);

    runs{r} = struct('arr',arr,'tg',tg,'pg',pg,'ref',ref,'svc',svc,'sA',sA,'sB',sB,'T',T);
end
R.runs = runs;
R.summary = summarize(runs, P);
end

function start = serve(arr, svc, pri, c)
% non-preemptive priority, c servers; ties -> earliest arrival
n = numel(arr); start = nan(n,1);
if n == 0, return, end
[arr,o] = sort(arr); svc = svc(o); pri = pri(o);
free = zeros(c,1); waiting = []; nxt = 1; done = 0; st = nan(n,1);
while done < n
    [t,s] = min(free);
    while nxt <= n && arr(nxt) <= t, waiting(end+1) = nxt; nxt = nxt+1; end %#ok<AGROW>
    if isempty(waiting)
        t = arr(nxt); waiting = nxt; nxt = nxt+1;
    end
    [~,k] = sortrows([-pri(waiting(:)) arr(waiting(:))]);
    j = waiting(k(1)); waiting(k(1)) = [];
    st(j) = t; free(s) = t + svc(j); done = done+1;
end
start(o) = st;
end

function S = summarize(runs, P)
m = @(x) mean(x,'omitnan');
nR = numel(runs); A = zeros(nR,4); B = zeros(nR,4);
for r = 1:nR
    q = runs{r}; sev = q.tg >= 3; need = q.tg >= 2;
    wA = q.sA - q.arr;  wB = q.sB - (q.arr + P.aiTime);
    A(r,:) = [m(wA) m(wA(sev)) 0 sum(q.sA > q.T)];
    B(r,:) = [m(wB(q.ref)) m(wB(sev & q.ref)) sum(need & ~q.ref)/max(sum(need),1) sum(q.ref & q.sB > q.T)];
end
S.meanWait_A  = mean(A(:,1));  S.meanWait_B  = mean(B(:,1));
S.sevWait_A   = mean(A(:,2));  S.sevWait_B   = mean(B(:,2));
S.missedRef_B = mean(B(:,3));
S.unserved_A  = mean(A(:,4));  S.unserved_B  = mean(B(:,4));
S.rho_A = P.lambda_day*P.svcMean/(P.nServers*P.clinicMin);
S.rho_B = S.rho_A * sum(P.prior(P.refThresh+1:end));
end