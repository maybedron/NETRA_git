R = run_district_sim();
P = R.P; q = R.runs{1}; S = R.summary;
tgrid = (0:P.clinicMin/8:q.T)';
days  = tgrid / P.clinicMin;
qlen = @(arr,st) arrayfun(@(t) sum(arr<=t) - sum(st<=t), tgrid);
LA = qlen(q.arr, q.sA);
LB = qlen(q.arr(q.ref)+P.aiTime, q.sB(q.ref));

dayA = floor(q.arr/P.clinicMin)+1;  wA = q.sA - q.arr;
dayB = dayA(q.ref);                 wB = q.sB(q.ref) - q.arr(q.ref) - P.aiTime;
dm = @(d,w) arrayfun(@(k) mean(w(d==k),'omitnan'), 1:P.days);

fig = figure('Position',[100 100 1000 700],'Visible','off');
subplot(2,1,1); plot(days,LA,'r','LineWidth',1.5); hold on; plot(days,LB,'b','LineWidth',1.5);
ylabel('Queue length (patients)'); legend('A: FIFO','B: AI triage'); grid on;
title(sprintf('District model (%d ophth., %d pts/day, %d days, assumed params)',P.nServers,P.lambda_day,P.days));
subplot(2,1,2); plot(1:P.days,dm(dayA,wA)/60,'r','LineWidth',1.5); hold on;
plot(1:P.days,dm(dayB,wB)/60,'b','LineWidth',1.5);
xlabel('Day'); ylabel('Mean wait (clinic-hours)'); grid on;
exportgraphics(fig,fullfile('..','results','district_sim.png'),'Resolution',200);

fprintf('Mean wait  A: %.1f h | B: %.1f h\n', S.meanWait_A/60, S.meanWait_B/60);
fprintf('Sev/PDR wait A: %.1f h | B: %.1f h\n', S.sevWait_A/60, S.sevWait_B/60);
fprintf('Missed referrals B (true grade>=2 not referred): %.1f%%\n', 100*S.missedRef_B);
fprintf('Utilization rho A: %.2f | B: %.2f\n', S.rho_A, S.rho_B);