function [y]=mod_noise(x,fs)

fmod = 0.5;
f=zeros(length(x),1);
y = f;
for i = 1:length(x)
    f(i) = 1 + 0.5*sin(2*pi*i*fmod/fs);
    y(i) = x(i).*f(i);
end