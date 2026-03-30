function [output,delayline_out] = FilterSample(x,w,delayline_in);
% 
% Sample x is filtered with filter w. If x has multiple columns,
% each column of x is filtered with w. If w has multiple colums,
% the data x is filtered with both columns of w.
%
% Inputs:
%   x             = input data (Dimensions:1xnr_channels)
%   w             = time-domain filter coefficients (Dimensions:filterlength x nr_filters)
%   delayline_in  = input delayline (Dimensions:filterlength x nr_channels)
% Outputs:  
%   output        = output data (Dimensions: 1 x max(nr_channels,nr_filters))
%   delayline_out = output delayline
% 
%Date: December, 2007  
%Copyright: (c) 2007 by Ann Spriet
%e-mail: ann.spriet@esat.kuleuven.be   

tmp = size(x); % size  = 1 
nr_channels=tmp(2); % lấy số cột của [1 , 2]
tmp = size(w);
nr_filters=tmp(2); % lấy số cột  = 1 

if and(nr_filters>1,nr_channels>1);
  error('Nr_channels and nr_filters cannot be both larger than 1');
end

delayline_out = [x;delayline_in(1:end-1,:)];  % delay_out bằng giống với delaysample nó phải là một mảng 1 chiều 


if nr_channels>1
  output = w'*delayline_out; % w' là chuyển vị của w
else
  output = delayline_out'*w; % delayline_out' là chuyển vị của delayline_out * w : nhân ma trận thì ôutput phải là 1 giá trị 
end

