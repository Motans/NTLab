x1 = sin(2*pi*[0:255]/1024); %quarter-period sine
x2 = sin(2*pi*[0:1023]/1024); %half-period sine
% Not correct repetition
x3 = [x1 x1(end:-1:1) -x1 -x1(end:-1:1)]; %repeat quarter-period sine to get half-period sine
% Correct repetition
x4 = [x1 1 x1(end:-1:2) -x1 -1 -x1(end:-1:2)]; %repeat quarter-period sine to get half-period sine
figure;
plot(x3-x2);
hold on
plot(x4-x2);
title('Sine repetition error')
legend('not correct', 'correct')