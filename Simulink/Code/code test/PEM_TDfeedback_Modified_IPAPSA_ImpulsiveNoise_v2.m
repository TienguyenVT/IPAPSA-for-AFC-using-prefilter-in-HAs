%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PEM_TDfeedback_Modified_IPAPSA.m
% Example file for using the time-domain implementation of the
% PemAFC-based feedback cancellation algorithm
% Modified by Linh Tran based on Ann Spriet's code 

% PEM-APA and PEM-IPAPA
% Author: Linh Tran
% Date: April 2016 and May 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
close all;
addpath('data_file');
addpath('CommonFunc\TD');
addpath('CommonFunc');
addpath('CommonFunc\Obj_estimate');
addpath('feedback cancellation_S');
addpath('C:\Documents\NCKH\IPAPSA for AFC using prefilter in HAs\Simulink\NOISEX-92');
% addpath('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\AlphaStableNoise');


%% Set Variables
prob_sig = 0;         % select among 0) without probe signal, 1)with probe signal as a white noise 
in_sig = 2;           % 0) white noise, 1) speech weighted noise, 2) real speech, 3) music
n_sel = 2;            % 0- no noise, 1-add wgn (generated), 2-add babble (from NOISEX-92), 
                      %3-add factory 2 noise (from NOISEX-92), other-add white noise (from NOISEX-92) to the incoming signal 
                    
fs = 16000;           % sampling frequency
N = 60*fs;            % total number of samples


Kdb = 30;             % gain of forward path in dB
K = 10^(Kdb/20);        
d_k = 96;             % delay of the forward path K(q) in samples 
d_fb = 1;             % delay of the feedback cancellation path in samples
Lg_hat = 64;          % the full length of adaptive filter
SNR = 30;             % amplified signal to injected noise ratio (dB)
SIR = 10;                
% Fixed Stepsize
mu = 8e-4;            % fixed step for APA, IPAPA
% mu = 0.001;         % fixed step size for NLMS, IPNLMS
% mu = 8e-6;          % fixed step for APSA,IPAPSA,MIPAPSA,BSMIPAPSA
mu1 = 8e-6/2;         % sw2: NLMS-PEMAPSA, mu1=8e-6/2, mu2=8e-2; Bernoulli-Gaussian noise as impulsive noise
mu2 = 8e-2;           % sw2: NLMS-PEMAPSA, mu1=8e-6/2, mu2=8e-3/2; Alpha-stable noise as impulsive noise
% mu1 = 8e-4;         % sw1: NLMS-PEMAPA, mu1=8e-4, mu2=8e-1; Bernoulli-Gaussian noise as impulsive noise   
% mu2 = 8e-1;         % sw1: NLMS-PEMAPA, mu1=8e-5, mu2=8e-3; Alpha-stable noise as impulsive noise 
delta = 1e-6;


% APA parameter
P = 2;              % Projection order
% BSMIPAPSA
M = 8;  % number of blocks

%%%%%%%%%%%%%%%%%%%%%%%%%
%Settings Feedback path %
%%%%%%%%%%%%%%%%%%%%%%%%%
%% Feedback path
   % Measured feedback path_no obstacle placed near the ear         
            
%     load FeedbackPath;
%     g11 = E(1:64);
% %       load Int_NormalFit_g1      % length = 21
% %       g11 = [Int_NormalFit_g1];
% %       g11 = g11-mean(g11);        % remove DC value in feedback path  
% %       g11 = [zeros(d_fb,1);g11(1:end);zeros(1,1)];
% %       Lg = length(g11);           % the length of true feedback path
% %       Nfreq = 128;
% %       G11 = fft(g11,Nfreq);  

load('mFBPathIRs16kHz_FF.mat');
E = mFBPathIRs16kHz_FF(:,3,1,1);
g = E - mean(E);  % feedback path and remove mean value
Lg = length(g);    % length of feedback path
Nfreq = 512;
G = fft(g,Nfreq);
      
   % Measured feedback path_with a flat obstacle placed closest to the ear
%       g12 = -g11;   
% %       load Int_ObjClosest_g1
% %       g12 = [Int_ObjClosest_g1];   
% %       g12 = g12-mean(g12);        % remove DC value in feedback path
% %       g12 = [zeros(d_fb,1);g12(1:end);zeros(1,1)];
% %       G12 = fft(g12,Nfreq);  

load('mFBPathIRs16kHz_PhoneNear.mat');
Ec = mFBPathIRs16kHz_PhoneNear(:,3,1);
gc = Ec - mean(Ec);  % feedback path and remove mean value
Gc = fft(gc,Nfreq);

TDLy = zeros(Lg,1);            %time-delay vector true feedback path
   
%%%%%%%%%%%%%%%%%%%%%%%%%
%Settings desired signal%
%%%%%%%%%%%%%%%%%%%%%%%%%
%% Desired Signal (incoming signal)

 if in_sig == 0     
    % 0) incoming signal is a white noise
    Var_noise =0.001;
    input = sqrt(Var_noise)*randn(N,1);
 elseif in_sig == 1
    % 1) incoming signal is a synthesized speech
    Var = 1;
    h_den = [1;-2*0.96*cos(3000*2*pi/15750);0.96^2];
%     h_den = [1;-0.8];     % a first-order system
    v = sqrt(Var)*randn(N,1);     % v[k] is white noise with variance one
    input = filter(1,h_den,v);        % speech weighted noise 
 elseif in_sig == 2
    % 2) incoming signal is a real speech segment from NOIZEUS
% %     load('HeadMid2_Speech_Vol095_0dgs_m1.mat')
% %     u = HeadMid2_Speech_Vol095_0dgs_m1(1:N,1); % 80s

    load('HeadMid2_Speech_Vol095_0dgs_m1.mat')
    input1 = HeadMid2_Speech_Vol095_0dgs_m1;
    input = input1(0.5*fs:end);

%     load('HeadMid2_Music_Vol095_0dgs_m1');      
%     input1 = HeadMid2_Music_Vol095_0dgs_m1;
%     input = input1(16000:end);
    
    
 else
    % 3) incoming signal is a music 
%     load('Ext_music_G30dB_0dgs_m1.mat')
%     u = Ext_music_G30dB_0dgs_m1(1:N,1); % 80s
    load('HeadMid2_Music_Vol095_0dgs_m1.mat')
    input1 = HeadMid2_Music_Vol095_0dgs_m1; % 80s
    input = input1(fs:end);
 end           
    input = input./max(abs(input));
    ff = fir1(64,[.025],'high');    
    u_ = filter(ff,1,input);  
    
 u = zeros(N,1); 
for k = 1 : N
    % loop through input signal
    if k <= length(u_)
        u(k) = u_(k);
    else
        u(k) = u_(rem(k,length(u_))+1,1);
    end  
end 

%%%%%%%%%%%%%%%%%%%%%%%%%
%Settings Probe signal  %
%%%%%%%%%%%%%%%%%%%%%%%%%
%% Probe signal w(k)
    Var_P = 0.001;
    if prob_sig == 1
        w = sqrt(Var_P)*randn(N,1);   % w[k] is a white noise;        
    else                            % With probe signal as a white noise        
        w = zeros(N,1);               % Without probe signal
    end
    
 % SNR
    if prob_sig == 1
        estKu = K * u;
        factor = SNRFactor(estKu,w,SNR);
        u = factor * u;
    end    
 
 % Impulsive noise
    % The impulsive noise is modeled as a Bernoulli-Gaussian (BG)distribution
%     pB = 0.1;   % The success probability for the Bernoulli process
%     varG = 1;
%     YB = Gen_Bernoulli_process(N,pB);
%     YG = wgn(N,1,varG);
%     YG = YG - mean(YG); % white Gaussian noise with zero mean and variance varG
%     n_imp = YB.*YG;     % impulsive noise 

    load('BGnoise_pB_0_1_varG_1.mat'); % n_imp with pB = 0.1; varG = 1;
    
    % The impulsive noise is modeled as Alpha-Stable Noise
%     alpha_imp = 1.8; % Stability parameter
%     beta_imp = 0; % Symmetric distribution
%     gamma_imp = 1; % Scale parameter
%     delta_imp = 0; % Location parameter

%     load('alpStabNoise_alp1_8_beta0_gam1_del0_60s.mat');
%     n_imp = noise;
    
 % Background noise (WGN or Babble noise or Factory 2 noise)
    % WGN
    Var_n = 1; % 0.001?
    nWGN = sqrt(Var_n)*randn(N,1);
    % after generating impulsive noise using above code, keep it the same
    % for all simulation by loading from the file below
    %load('PEM_BSMIPAPSA_K30_La20_P2_mu8e-6_deltaIP_SIR0_SNR30_whiteNoise_alpStabNoise_spch60s.mat')
    
    % Babble noise from NOISEX-92
    [n_babble,fs_n] = audioread('babble.wav');
    [pn,qn] = rat(fs/fs_n);
    n_bab = resample(n_babble,pn,qn);
    n_bab = n_bab(1:N,1);
    
    % Factory 2 noise from NOISEX-92
    [n_factory2,fs_fac2] = audioread('factory2.wav');
    [pn2,qn2] = rat(fs/fs_fac2);
    n_fac2 = resample(n_factory2,pn2,qn2);
    n_fac2 = n_fac2(1:N,1);
    
    % White noise from NOISEX-92
    [n_white,fs_w] = audioread('white.wav');
    [pn3,qn3] = rat(fs/fs_w);
    n_w = resample(n_white,pn3,qn3);
    n_w = n_w(1:N,1);
    
 % add bgr noise and Impulsive noise to signal with a specific SNR, SIR = 0 dB
 [u_imp,scaled_imp] = add_noise(u,n_imp,SIR);
    if n_sel == 0   % no (bgr noise and Impulsive noise)
        u = u;
    elseif n_sel == 1   % bgr noise is white noise
        [u_WGN] = add_noise(u,nWGN,SNR);
        u = u_WGN + scaled_imp;
    elseif n_sel == 2 % bgr noise is babble noise from NOISEX-92
        [u_bab] = add_noise(u,n_bab,SNR);        
        u = u_bab + scaled_imp;
    elseif n_sel == 3 % bgr noise is factory 2 noise from NOISEX-92
        [u_fac2] = add_noise(u,n_fac2,SNR);        
        u = u_fac2 + scaled_imp;
    else    % bgr noise is white noise from NOISEX-92
        [u_w] = add_noise(u,n_w,SNR);        
        u = u_w + scaled_imp;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%
% Pre-whitening filter  %
%%%%%%%%%%%%%%%%%%%%%%%%%
     
La = 20;
framelength = 0.01*fs;
% [AF,AR] = PemAFCinit_APA(Lg_hat,La,framelength,P,delta); % for Ann's measure
%       FB path
[AF,AR] = PemAFCinit_APA(Lg_hat,M,mu,mu1,mu2,La,framelength,P,delta); % for our measure
%       FB path
% [AF,AR] = PemAFCinit(Lg_hat,La,framelength);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%initialisation data vectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

y = zeros(N,1);         % loudspeaker signal
yuL = zeros(N,1);     % unlimited loudspeaker signal

e_delay = zeros(N+d_k,1);
e1_delay = zeros(N+d_k,1);
y_delayfb = zeros(N+d_fb,1);
m = zeros(N,1);         % received microphone signal

% performance parameters
MIS = zeros(N,1);
MSG = zeros(N,1);
ASG = zeros(N,1);

% ewh = zeros(N,1);
%%%%%%%%%%%%%%%%%%%%%%%%%
% PEM lattice algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%
% ewh(1)=0;

alpha = zeros(N,1); %control signal for switching

for k = 2:N 
    % Change the feedback path at sample N/2
    if k == N/2
       g = gc;       
       G = Gc;  
    end
    
%        y(k) = K*e_delay(k) + w(k);
        y(k) = K*e1_delay(k) + w(k);
%      y(k) = tanh(K*e_delay(k) + w(k));
     
%      % unlimited output
%      yuL(k) = K*e_delay(k)+w(k);
%      
%      clip = abs(y(k)-yuL(k));
%      if clip >.6
%          mu = 10*Mu;
%      else
%          mu = Mu;
%      end

     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     % Simulated feedback path: computation of microphone signal
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
      TDLy = [y(k);TDLy(1:end-1,1)];
      m(k) = u(k) + g'*TDLy;        %received microphone signal
     
      y_delayfb(k+d_fb) = y(k);     
%       g_trunc = g(1:Lg_hat);        % truncate the true feedback path
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %Feedback cancellation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       [e_delay(k+d_k),AF,AR] = PemAFC_Modified_SC_IPAPA(m(k),y_delayfb(k),AF,AR,1,14);  % for our measure

      [e1_delay(k+d_k),AF,AR,aaa] = PemAFC_Modified_SC_IPAPA_stud(m(k),y_delayfb(k),AF,AR,1,6);  % for our measure
      alpha(k) = aaa;

%       [e_delay(k+d_k),AF,AR] = PemAFC_Modified_GGP(g_trunc,m(k),y_delayfb(k),AF,AR,1);  % for our measure
%       [e_delay(k+d_k),AF,AR,beta_RIPAPA] = PemAFC_Modified_RegIPAPA(m(k),y_delayfb(k),AF,AR,1);  % for our measure 
%       FB path
%       [e_delay(k+d_k),AF,AR] = PemAFC_Modified_APA(m(k),y_delayfb(k),mu,AF,AR,1);   % for Ann's measure
%       FB path   
    
 %  Misaligment of the PEM-AFC
    g_hat = [zeros(d_fb,1);AF.gTD];
    G_hat = fft(g_hat,Nfreq);
    G_tilde = G(1:ceil(Nfreq/2))-G_hat(1:ceil(Nfreq/2));
    
    % Misalignment
    MIS(k) = 20*log10(norm(G_tilde)/norm(G(1:ceil(Nfreq/2))));
    
    % Maximum Stable Gain (MSG)    
    MSG(k) = 20*log10(min(1./abs(G_tilde)));    
    
    % Added Stable Gain (ASG)
    ASG(k) = MSG(k)-20*log10(min(1./abs(G(1:Nfreq/2+1)))); 
end

%% Performace 
    t = linspace(0,(N-1)/fs,N);
     % Misalignment 
     figure(100);
     plot(t,MIS,'b','LineWidth',1); grid on
     xlabel('Time [s]');
     ylabel('MIS [dB]');
     legend ('sw1-NLMS and PEMAPA');
%      legend ('sw2-NLMS and PEMAPSA');
%      legend ('sw2.1-PEMNLMS and PEMAPSA, P = 8'); % not good
%      legend ('sw1.1-NLMS and PEMAPA, P = 8');
%      legend ('HNLMS');
%      title('PEM-APA, P=2, dk=96, mu=0.002');
%     title('approx. tanh(), a=1');
%      legend (['PEM-APA,P=2, \mu=' num2str(mu)]);
%     legend (['PEM-APSA,P=2, \mu=' num2str(mu)]);
     
     % MSG
%      figure(200);
%      plot(t,MSG);grid on
%      xlabel('Time [s]');
%      ylabel('MSG [dB]'); 
%      title('PEM-APA, P=2, dk=64, mu=0.0022');
    
    % ASG
     figure(300);
     plot(t,ASG,'b','LineWidth',1);grid on
     xlabel('Time [s]');
     ylabel('ASG [dB]'); 
%      legend ('sw1-NLMS and PEMAPA');
%      legend ('sw2-NLMS and PEMAPSA');
%     legend ('HNLMS');
%     legend ('sw3-NLMS and PEMAPSA, P = 8');
%     legend ('sw2.1-PEMNLMS and PEMAPSA, P = 8');% not good
%     legend ('sw1.1-NLMS and PEMAPA, P = 8');
%      title('PEM-APA, P=2, dk=64, mu=0.0022');
%     title('approx. tanh(), a=1');

figure(400);plot(t,y); grid on; 
xlabel('Time [s]');
ylabel('Amplitude');
% legend (['PEM-APA, P=6, \mu=' num2str(mu)]);
% legend (['PEM-BSMIPAPSA, P=2, \mu=' num2str(mu)]);
% legend (['PEM-NLMS, \mu=' num2str(mu)]);
% % legend (['PEM-IPNLMS, \mu=' num2str(mu)]);
% legend (['PEM-NLMS, \mu=' num2str(mu)]);
% legend (['PEM-APA, P=2, \mu=' num2str(mu)]);
% legend (['PEM-APSA, P=2, \mu=' num2str(mu)]);
legend ('sw1-NLMS and PEMAPA');
% legend ('sw2-NLMS and PEMAPSA');
% legend ('sw2.1-PEMNLMS and PEMAPSA, P = 8');% not good
% legend ('sw1.1-NLMS and PEMAPA, P = 8'); % sel_alg == 16: not good
% legend ('HNLMS');
% title('approx. tanh(), a=1');

% Average values of MisAL, MSG, ASG
aveMIS1 = mean(MIS(2:N/2-1));
aveMIS2 = mean(MIS(N/2+1:N));
% aveMSG = mean(MSG)
aveASG1 = mean(ASG(2:N/2-1));
aveASG2 = mean(ASG(N/2+1:N));

% Last values of MisAL, MSG, ASG
% Last_MisAL = MIS(N)
% Last_MSG = MSG(N)
% Last_ASG = ASG(N)

% PESQ
% PESQ = pesq2(u(3:N),y(3:N),fs)
% PESQ = pesq2(u,y,fs)
PESQ1 = pesq2(u(3:N/2),y(3:N/2),fs);
PESQ2 = pesq2(u(N/2+1:end),y(N/2+1:end),fs);
% 
PESQ1_15s_30s = pesq2(u(15*fs:30*fs-1),y(15*fs:30*fs-1),fs);
PESQ2_45s_60s = pesq2(u(45*fs:60*fs),y(45*fs:60*fs),fs);
% PESQ1_20s_28s = pesq2(u(20*fs:28*fs),y(20*fs:28*fs),fs)
% PESQ2_52s_60s = pesq2(u(52*fs:60*fs),y(52*fs:60*fs),fs)

% figure(110);
%      plot(t,alpha,'b','LineWidth',0.75); grid on
%      xlabel('Time [s]');
%      ylabel('\beta(k)');
% %      legend ('sw1-NLMS and PEMAPA');
% %      legend ('sw2-NLMS and PEMAPSA');
%      title('\gamma = 2, \kappa = 0.15');
%      
%      
%      figure(120);
%      plot(t,e_delay(97:end,1)','b','LineWidth',0.75); grid on
%      xlabel('Time [s]');
%      ylabel('Amplitude');
% %      legend ('sw1-NLMS and PEMAPA');
% %      legend ('sw2-NLMS and PEMAPSA');
%      title('\gamma = 2, \kappa = 0.15');


% save for speech
% % save('G:\Linh\12Apr2017\Sim Results\February2016\PEM-PNLMS\IPNLMS_l0\sigmaDiv2L\IPAPA\Result_RegularizationIPAPA_Aug2019\Test_oneScript_IPAPA\evaluatePEM_IPAPA_K30_La20_mu0008_P2_del10e-6_60s.mat','MIS','MSG','ASG','u','y','e_delay','aveMis','aveASG','PESQ','PESQ1','PESQ2','PESQ1_20s_28s','PESQ2_52s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\evalPEM_APSA_K30_La20_mu8e-6_del1e-6_SIR0_SNR10_wgn_Var1_mean0_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay');
% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\evalPEM_IPAPSA_K30_La20_mu8e-6_delIPAPA_SIR0_SNR10_fac2_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay');
% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\evalPEM_IPNLMS_K30_La20_mu1e-3_del1e-6_SIR0_SNR10_white_Noisex92_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay');
% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\evalPEM_IPAPA_K30_La20_mu8e-4_delIPAPA_SIR0_SNR20_fac2_spch60s_rerun.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay');
% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\evalPEM_APSA_K30_La20_mu8e-6_delIPAPA_SIR0_SNR20_fac2_spch60s_rerun.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay');
% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\evalPEM_IPNLMS_K30_La20_mu1e-3_del1e-6_SIR0_SNR10_white_Noisex92_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay');

% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\AlphaStableNoise_fixed\PEM_IPNLMS_K30_La20_mu1e-3_deltaIP_SIR0_SNR30_whiteNoisex92_alpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\AlphaStableNoise_fixed\PEM_NLMS_K30_La20_mu1e-3_del1e-6_SIR0_SNR30_whiteNoisex92_alpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\AlphaStableNoise_fixed\PEM_APA_K30_La20_P2_mu8e-4_del1e-6_SIR0_SNR30_whiteNoisex92_alpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% % save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\AlphaStableNoise_fixed\PEM_IPAPA_K30_La20_P2_mu8e-4_deltaIP_SIR0_SNR30_whiteNoisex92_alpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\AlphaStableNoise_fixed\PEM_IPAPSA_K30_La20_P2_mu8e-6_deltaIP_SIR0_SNR30_whiteNoise_alpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\AlphaStableNoise_fixed\PEM_BSMIPAPSA_K30_La20_P2_mu8e-6_deltaIP_SIR0_SNR30_WhiteNoisex92_alpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');

% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\AlphaStableNoise_fixed\PEM_IPNLMS_K30_La20_mu1e-3_deltaIP_SIR0_SNR30_BabbleNoisex92_alpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\AlphaStableNoise_fixed\PEM_NLMS_K30_La20_mu1e-3_del1e-6_SIR0_SNR30_BabbleNoisex92_alpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\AlphaStableNoise_fixed\L2_PEM_APA_K30_La20_P2_mu8e-4_del1e-6_SIR0_SNR30_BabbleNoisex92_alpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\AlphaStableNoise_fixed\PEM_IPAPA_K30_La20_P2_mu8e-4_deltaIP_SIR0_SNR30_BabbleNoisex92_alpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\AlphaStableNoise_fixed\PEM_IPAPSA_K30_La20_P2_mu8e-6_deltaIP_SIR0_SNR30_BabbleNoise_alpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% % save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\AlphaStableNoise_fixed\PEM_BSMIPAPSA_K30_La20_P15_mu8e-6_deltaIP_SIR0_SNR30_BabbleNoisex92_alpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');

% save('G:\Linh\Backup2017\Proposed_Papers\PEM-BS-MIPAPSA\ex_results\PEM_APA_K30_La20_mu8e-4_deltaIP_SIR0_SNR20_fac2_spch60s_rerun.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay');

% save for music
% save('G:\Linh\12Apr2017\Sim Results\February2016\PEM-PNLMS\IPNLMS_l0\sigmaDiv2L\IPAPA\Result_RegularizationIPAPA_Aug2019\evaluatePEM_IPAPA_music1s_K30_La20_mu0008_P2_del10e-6_60s.mat','MIS','MSG','ASG','u','y','e_delay','aveMis','aveASG');
% soundsc(y,fs);
% save('G:\Linh\12Apr2017\Sim Results\February2016\PEM-PNLMS\IPNLMS_l0\sigmaDiv2L\IPAPA\Result_RegularizationIPAPA_Aug2019\evaluateIPAPA_K30_La20_mu001_P2_del20_60s.mat','MIS','MSG','ASG','u','y','aveMis','aveASG','PESQ');

%% results for sw2 paper
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Bernoulli_Gaussian_noise_L2\sw1_NLMS_PEMAPA_P2_K30_La20_mu1_8e-4_mu2_8e-1_delta1e-6_SIR10_SNR20_whiteNoisex92_BGnoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% % save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Bernoulli_Gaussian_noise_L2\sw2_NLMS_PEMAPSA_approx_a_1_P2_K30_La20_mu1_8e-6_mu2_8e-2_delta1e-6_SIR10_SNR30_whiteNoisex92_BGnoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Bernoulli_Gaussian_noise_L2\PEMAPSA_P2_K30_La20_mu_8e-6_delta1e-6_SIR10_SNR20_whiteNoisex92_BGnoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Bernoulli_Gaussian_noise_L2\PEMIPAPA_P2_K30_La20_mu_8e-4_deltaIP_SIR10_SNR20_whiteNoisex92_BGnoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Bernoulli_Gaussian_noise_L2\PEMAPA_P2_K30_La20_mu_8e-4_delta1e-6_SIR10_SNR20_whiteNoisex92_BGnoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');

% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Bernoulli_Gaussian_noise_L2\sw1_NLMS_PEMAPA_P2_K30_La20_mu1_8e-4_mu2_8e-1_delta1e-6_SIR10_SNR30_babbleNoisex92_BGnoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Bernoulli_Gaussian_noise_L2\sw2_NLMS_PEMAPSA_P2_K30_La20_mu1_8e-6div2_mu2_8e-2_delta1e-6_SIR10_SNR30_babbleNoisex92_BGnoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Bernoulli_Gaussian_noise_L2\PEMAPSA_P2_K30_La20_mu_8e-6_delta1e-6_SIR10_SNR30_babbleNoisex92_BGnoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Bernoulli_Gaussian_noise_L2\PEMIPAPA_P2_K30_La20_mu_8e-4_deltaIP_SIR10_SNR30_babbleNoisex92_BGnoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Bernoulli_Gaussian_noise_L2\PEMAPA_P2_K30_La20_mu_8e-4_delta1e-6_SIR10_SNR20_babbleNoisex92_BGnoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');

% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Alpha_stable_noise\sw1_NLMS_PEMAPA_P2_K30_La20_mu1_8e-5_mu2_8e-3_delta1e-6_SIR10_SNR30_whiteNoisex92_AlpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Alpha_stable_noise\sw2_NLMS_PEMAPSA_P2_K30_La20_mu1_8e-6div2_mu2_8e-3div5_delta1e-6_SIR10_SNR30_whiteNoisex92_AlpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Alpha_stable_noise\PEMAPSA_P2_K30_La20_mu_8e-6_delta1e-6_SIR10_SNR30_whiteNoisex92_AlpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Alpha_stable_noise\PEMIPAPA_P2_K30_La20_mu_8e-4_deltaIP_SIR10_SNR30_whiteNoisex92_AlpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Alpha_stable_noise\PEMAPA_P2_K30_La20_mu_8e-4_delta1e-6_SIR10_SNR30_whiteNoisex92_AlpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');


% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Alpha_stable_noise\sw1_NLMS_PEMAPA_P2_K30_La20_mu1_8e-5_mu2_8e-3_delta1e-6_SIR10_SNR30_babbleNoisex92_AlpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Alpha_stable_noise\sw2_NLMS_PEMAPSA_P2_K30_La20_mu1_8e-6div2_mu2_8e-3div2_delta1e-6_SIR10_SNR30_babbleNoisex92_AlpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Alpha_stable_noise\PEMAPSA_P2_K30_La20_mu_8e-6_delta1e-6_SIR10_SNR30_babbleNoisex92_AlpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Alpha_stable_noise\PEMIPAPA_P2_K30_La20_mu_8e-4_deltaIP_SIR10_SNR30_babbleNoisex92_AlpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Alpha_stable_noise\PEMAPA_P2_K30_La20_mu_8e-4_delta1e-6_SIR10_SNR30_babbleNoisex92_AlpStabNoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
%% additional results 
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\Bernoulli_Gaussian_noise_L2\sw1_NLMS_PEMAPA_P2_K30_La20_mu1_8e-4_mu2_8e-1_delta1e-6_SIR10_SNR20_whiteNoisex92_BGnoise_spch60s.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\BerGauss_noise_addition\sw2_NLMS_PEMAPSA_gamm0.5_kapp0.15_P2_K30_La20_mu1_4e-6_mu2_8e-2_delta1e-6_SIR10_SNR30_whiteNoisex92_BGnoise_spch60s.mat','aaa','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\BerGauss_noise_addition\sw2_scl-3dB_NLMS_PEMAPSA_gamm2_kapp0.15_P2_K45_La20_mu1_4e-6_mu2_8e-2_del1e-6_SIR10_SNR30_Babble_BGnoise_spch.mat','aaa','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\BerGauss_noise_addition\PEMAPA_gamm2_kapp0.15_P2_K45_La20_mu_8e-4_del1e-6_SIR10_SNR30_Babble_BGnoise_music.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\BerGauss_noise_addition\sw2_ek_NLMS_PEMAPA_gamm2_kapp0.15_P2_K30_La20_mu1_4e-6_mu2_8e-2_delta1e-6_SIR10_SNR30_Babble_BGnoise_spch.mat','aaa','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\BerGauss_noise_addition\sw1_scl3dB_NLMS_PEMAPA_gamm2_kapp0.15_P2_K45_La20_mu1_8e-4_mu2_8e-1_delta1e-6_SIR10_SNR30_Babble_BGnoise_spch.mat','aaa','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\BerGauss_noise_addition\PEMAPSA_gamm2_kapp0.15_P2_K45_La20_mu_8e-6_delta1e-6_SIR10_SNR30_Babble_BGnoise_music.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\BerGauss_noise_addition\PEMAPSA_gamm2_kapp0.15_P2_K45_La20_mu_8e-6_del1e-6_SIR10_SNR30_Babble_BGnoise_spch.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay','PESQ1','PESQ2','PESQ1_15s_30s','PESQ2_45s_60s');
% save('G:\Linh\Backup2017\Proposed_Papers\sw2-PEMSC\results\BerGauss_noise_addition\PEMAPSA_gamm2_kapp0.15_P2_K45_La20_mu_8e-6_delta1e-6_SIR10_SNR30_Babble_BGnoise_music.mat','aveMIS1','aveMIS2','aveASG1','aveASG2','u','y','e_delay');



% soundsc(y,fs)
