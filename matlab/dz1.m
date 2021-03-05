pkg load signal;

fd = 2^10;
fin = 10;
f = 3;

function y = dc_rem_filt(x, alpha)
  y = zeros(size(x));
  buf = 0;
  
  for i=1:length(x)
    y(i) = x(i) + buf;
    buf = alpha*y(i) - x(i);
  endfor
endfunction

t = 0:1/fd:fin;

x = sin(2*pi*f*t) - 4;
y = dc_rem_filt(x, 0.992);

figure;
  subplot(211);
  plot(t, x);
  
  subplot(212);
  plot(t, y);