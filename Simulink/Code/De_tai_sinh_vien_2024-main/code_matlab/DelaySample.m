function [output,delayline_out] = DelaySample(x,delay,delayline_in);
% Delays sample x with delay. 
%
% INPUTS:
%   x             = input data (Dimensions:1 x nr_channels) 
%   delay         = discrete-time delay
%   delayline_in  = input delayline (Dimensions:(delay+1) x nr_channels)
% OUTPUTS:  
%   output        =  output data (Dimensions: 1 x nr_channels)
%   delayline_out = output delayline
% 
%Date: December, 2007  
%Copyright: (c) 2007 by Ann Spriet
%e-mail: ann.spriet@esat.kuleuven.be   

delayline_out = [x;delayline_in(1:end-1,:)]; % x sẽ được thêm vào vị trí thứ 1 và các phần tử còn lại sẽ được dịch chuyển về phía sau 1 đơn vị
output = delayline_out(delay+1,:); % lấy ra phần tử thứ delay+1 của delayline_out

end
