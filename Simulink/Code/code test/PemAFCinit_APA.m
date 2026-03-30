function [AF,AR] = PemAFCinit_APA(N,M,mu,mu1,mu2,N_ar,framelength_ar,P,delta)
% function [AF,AR] = PemAFCinit_APA(N,mu,mu1,mu2,N_ar,framelength_ar,P,delta)
%
%function [AF,AR] = PemAFCinit(N,mu,N_ar,framelength_ar)
%  
%Initialization of time-domain LMS-based implementation of PEM-based
%adaptive feedback canceller; Used in combination with PemAFC.m
%
%INPUTS:
% * N    = filter length of the adaptive feedback canceller
% * mu   = step-size of the NLMS-based adaptive feedback canceller  
% * N_ar = filter length of the AR model
% * framelength_ar = framelength in number of samples on which the AR model is estimated  
%
%OUTPUTS: 
% * AF        = time-domain feedback canceller and its properties
%                -AF.wTD: coefficients of the time-domain feedback canceller
%                -AF.N  : filter length
%                -AF.mu : step size
%                -AF.p  : power in step-size normalization
%                -AF.lambda: weighing factor for power computation
%                -AF.TDLLs: time-delay line of loudspeaker samples
%                           (dimensions: AF.N x 1)
%                -AF.TDLLswh: time-delay line of pre-whitened loudspeaker
%                             samples (dimensions: AF.N x 1)
% * AR        = auto-regressive model and its properties
%                -AR.w           : coefficients of previous AR-model
%                -AR.N           : filter length AR model (Note: N=Nh+1)
%                -AR.framelength : framelength on which AR model is estimated
%                -AR.TDLMicdelay : time-delay line of microphone samples
%                                  (dimensions: AR.framelength+1 x 1)
%                -AR.TDLLsdelay  : time-delay line of loudspeaker samples
%                                  (dimensions: AR.framelength+1 x 1)
%                -AR.TDLMicwh    : time-delay line of pre-whitened
%                                  microphone signal
%                                  (dimensions: AR.N x 1)
%                -AR.TDLLswh     : time-delay line of pre-whitened
%                                  loudspeaker signal
%                                  (dimensions: AR.N x 1)
%                -AR.frame       : frame of AR.framelength error signals
%                                  on which AR model is computed  
%                -AR.frameindex
%
%
%
%Date: December, 2007  
%Copyright: (c) 2007 by Ann Spriet
%e-mail: ann.spriet@esat.kuleuven.be
% modified by Linh Tran
  
AR.N=N_ar;
AR.w=[1;zeros(AR.N-1,1)];
AR.framelength=framelength_ar;
AR.frameindex=0;
AR.TDLMicdelay=zeros(AR.framelength+1,1);
AR.TDLLsdelay=zeros(AR.framelength+1,1);
AR.TDLMicwh=zeros(AR.N,1);
AR.TDLLswh=zeros(AR.N,1);
AR.frame=zeros(AR.framelength,1);

AF.gTD = zeros(N,1);

AF.N = N;           % length of AF
AF.P = P;           % projection order for APA
AF.M = M;           % number of blocks

AF.mu = mu;
AF.mu1 = mu1;
AF.mu2 = mu2;
AF.delta = delta;
AF.TDLLs = zeros(N,1);
AF.TDLLswh = zeros(N,1);
AF.TDLLswh_d=zeros(N+P-1,1);
AF.Lswh_ap = zeros(N,P);
AF.TDLMicwh = zeros(P,1);

AF.TDLLs_d=zeros(N+P-1,1);
AF.Ls_ap = zeros(N,P);
AF.TDLMic = zeros(P,1);
AF.Qd = zeros(N,P);

AF.pow_Micwh = 0;
AF.pow_ep = 0;
AF.pow_Lswh = 0;
AF.pow_vp_hat = 0;

eps = 1e-5;
% AF.R_m = zeros(N,N);
AF.R_mu = eps*eye(N);
AF.pow_w = 1e-10;
AF.r_mu = eps;

% AF.delta = zeros(N,1);

% AF.p = 0;
% AF.lambda = exp(log(0.6)/AF.N);
