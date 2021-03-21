
pkg load signal;

function y = sin_d(x, word_len)
  y = fix(sin(x) * (2^(word_len-1)));
endfunction

function y = cos_d(x, word_len)
  y = fix(cos(x) * (2^(word_len-1)));
endfunction

function [dout, cm1, buf] = iq_comp(din, cm1, buf, i)
  dout = din - cm1;
  
  a = real(dout);
  b = imag(dout);
  cm2 = fix(a^2 / 2^18) - fix(b^2 / 2^18) +\
        j*2*fix(a*b / 2^18);
  
  conv1 = cm2 * 2^16;
  conv1 = conv1 / 2^8;
  
  sum1 = buf;
  buf = buf + conv1;
    
  conv2 = fix(sum1 / 2^16);
  conj1 = conj(din);
  a = real(conv2);
  b = imag(conv2);
  c = real(conj1);
  d = imag(conj1);
##  CM1 = FIX(A*C / 2^18) - FIX(B*D / 2^18) +\
##     J*(FIX(A*D / 2^18) + FIX(B*C / 2^18));
  cm1 = bitshift(a*c, -18) - bitshift(b*d, -18) +\
     j*(bitshift(a*d, -18) + bitshift(b*c, -18));
##cm1 = fix(conj1*conv2 / 2^18);
  if(i < 32)
    din
    dout
    cm2
    conv1
    sum1
    buf
    conv2
    conj1
    cm1
  endif
endfunction

cm1 = 0;
buf = 0;

sin_x = load("im_in.txt");
cos_x = load("re_in.txt");
out_im = load("im_out.txt");
out_re = load("re_out.txt");

sin_x = sin_x';
cos_x = cos_x';
out_im = out_im';
out_re = out_re';

y = zeros(1, 2^14);
x = zeros(1, 2^14);
xx = cos_x + j*sin_x;
yy = out_re + j*out_im;

for i = 0:(2^14-1) 
  x(i+1) = xx(i+1);
  [y(i+1), cm1, buf] = iq_comp(x(i+1), cm1, buf, i);
endfor

x_fft = fft(x);
y_fft = fft(y);
xx_fft = fft(xx);
yy_fft = fft(yy);

figure;
  subplot(321);
  hold on;
  plot(real(x(1:256)));
  plot(imag(x(1:256)));

  subplot(322);
  hold on;
  plot(real(y(1:256)));
  plot(imag(y(1:256)));

  subplot(323);
  hold on;
  plot(real(x(end-256:end)));
  plot(imag(x(end-256:end)));

  subplot(324);
  hold on;
  plot(real(y(end-256:end)));
  plot(imag(y(end-256:end)));

  subplot(3,2,[5,6]);
  hold on;
  plot(abs(y_fft));
  plot(abs(yy_fft));

figure;

plot(abs(y - yy) / 2^17);