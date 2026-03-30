function [e,AF,AR,aa,xi_sc] = PemAFC_Modified_SC_IPAPA_stud(Mic,Ls,AF,AR,UpdateFC,sel_alg)
%
%function [e,AF,AR] = PemAFC(Mic,Ls,AF,AR,UpdateFC,RemoveDC)
%  
%Update equation of time-domain LMS-based implementation of PEM-based
%adaptive feedback canceller
%
%INPUTS:
% * Mic = microphone sample
% * Ls  = loudspeaker sample
% * AF  = time-domain LMS-based feedback canceller and its properties
%          -AF.wTD: time-domain filter coefficients (dimensions: AF.N x 1)  
%          -AF.N  : time-domain filter length
%          -AF.mu : stepsize
%          -AF.p  : power in step-size normalization
%          -AF.lambda: weighing factor for power computation
%          -AF.TDLLs: time-delay line of loudspeaker samples
%          (dimensions: AF.N x 1)
%          -AF.TDLLswh: time-delay line of pre-whitened loudspeaker
%          samples (dimensions: AF.N x 1)
%
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
% * UpdateFC = boolean that indicates whether or not the feedback canceller should be updated 
%                    (1 = update feedback canceller; 0 = do not update feedback canceller)  
% * RemoveDC   = boolean that indicates whether or not the DC component of the estimated feedback path should be removed 
%                    (1 = remove DC of feedback canceller; 0 = do not remove DC of feedback canceller)  
%OUTPUTS:
% * e          = feedback-compensated signal 
% * AR         = updated AR-model and its properties
% * AF         = updated feedback canceller and its properties 
%
%
%
%Date: December, 2007  
%Copyright: (c) 2007 by Ann Spriet
%e-mail: ann.spriet@esat.kuleuven.be

% PEM-APA and PEM-IPAPA
% Author: Linh Tran
% Date: April 2016 and May 2016

beta = 50;
AF.TDLLs = [Ls;AF.TDLLs(1:end-1,1)];
e     = Mic - AF.gTD'*AF.TDLLs;
hv = e;
e = 2*tanh(0.5*e);                      % limit the error signal
aaa = (abs(hv-e)<.15);

%Delay microphone and loudspeaker signal by framelength
[Micdelay,AR.TDLMicdelay] = DelaySample(Mic,AR.framelength,AR.TDLMicdelay); 
[Lsdelay,AR.TDLLsdelay] = DelaySample(Ls,AR.framelength,AR.TDLLsdelay);

% Filter microphone and loudspeaker signal with AR-model
[Micwh,AR.TDLMicwh] = FilterSample(Micdelay,AR.w,AR.TDLMicwh);
[Lswh,AR.TDLLswh]   = FilterSample(Lsdelay,AR.w,AR.TDLLswh);

%Update AR-model  
AR.frame=[e;AR.frame(1:AR.framelength-1)];
     
if and(AR.frameindex==AR.framelength-1,AR.N-1>0)
  R=zeros(AR.N,1);
  for j= 1:AR.N
     R(j,1) = (AR.frame'*[AR.frame(j:length(AR.frame)); zeros(j-1,1)])/AR.framelength;
  end
  [a,Ep] = levinson(R,AR.N-1);
  AR.w=a';
end

AR.frameindex = AR.frameindex+1;
      
if AR.frameindex == AR.framelength
  AR.frameindex = 0;
end

AF.TDLLswh = [Lswh;AF.TDLLswh(1:end-1,1)];
ep = Micwh - AF.gTD'*AF.TDLLswh;

if UpdateFC == 1    
       
    % APA alg. with pre-filters
    AF.TDLMicwh = [Micwh;AF.TDLMicwh(1:end-1,1)];   % size=(P,1);
    AF.TDLLswh_d = [Lswh;AF.TDLLswh_d(1:end-1,1)];  % size=(Lg_hat+P-1,1);      
    AF.Lswh_ap = AP_alg(AF.P,AF.N,AF.TDLLswh_d);    % size=(Lg_hat,P);    
    ewh_p = AF.TDLMicwh - AF.Lswh_ap'*AF.gTD;       % size=(P,1);
    
    % APA alg. without pre-filters
    AF.TDLMic = [Mic;AF.TDLMic(1:end-1,1)];         % size=(P,1);
    AF.TDLLs_d = [Ls;AF.TDLLs_d(1:end-1,1)];        % size=(Lg_hat+P-1,1);
    AF.Ls_ap = AP_alg(AF.P,AF.N,AF.TDLLs_d);        % size=(Lg_hat,P);
    e_ap = AF.TDLMic - AF.Ls_ap'*AF.gTD;            % size=(P,1);
    
            
    % Sparseness measure 
    delta_sc = 1e-8;
    gamma = length(AF.gTD)/(length(AF.gTD) - sqrt(length(AF.gTD)));
    xi_sc = gamma * (1 - sum(abs(AF.gTD)) / (sqrt(length(AF.gTD))*norm(AF.gTD) + delta_sc));
    
    % Compute 
    lda = 6;
%     gamma = 0.999;    
    if sel_alg == 0
        aa = 0;             % not use for this case
                       
        % NLMS
        %PEM_NLMS_term = AF.TDLLswh .* conj(ep)/(norm(AF.TDLLswh)^2 + AF.delta);
        %AF.gTD = AF.gTD + (AF.mu/(norm(AF.TDLLswh)^2 + AF.delta))*AF.TDLLswh.*ep;
        %AF.gTD = AF.gTD + AF.mu*PEM_NLMS_term;
        
%         AF.pow_Lswh = gamma * AF.pow_Lswh + (1 - gamma) * Lswh^2;        
%         if AF.P == 1    % Note: much worse performance than fixed delta=1e-6
%             % PEM-NLMS
%             delta_APA = 20*AF.pow_Lswh + AF.delta;
%         else
%             delta_APA = 25*AF.P*AF.pow_Lswh + AF.delta;
%         end
        
        % classical NLMS and APA (P=1 -> NLMS-l1; P=2 -> APA-l1)
        PEM_APA_term = AF.Lswh_ap*inv(AF.Lswh_ap'*AF.Lswh_ap+AF.delta*eye(AF.P))*ewh_p;
%         PEM_APA_term = AF.Lswh_ap*inv(AF.Lswh_ap'*AF.Lswh_ap+AF.delta*eye(AF.P))*ewh_p;
        AF.gTD = AF.gTD + AF.mu*PEM_APA_term;
        % or
        % AF.gTD = AF.gTD + AF.mu*AF.Lswh_ap*inv(AF.Lswh_ap'*AF.Lswh_ap+AF.delta*eye(AF.P))*ewh_p;
    elseif sel_alg == 1
        % IPNLMS-l1 norm proposed by Benesty and Gay, 2002
        % IPAPA-l1 norm proposed by 
        % [1] [O Hoshuyama, RA Goubrant, A Sugiyama]_ICASSP2004_A generalized proportionate variable step-size algorithm for fast changing acoustic environments
        % [2] [K Sakhnow]_C2008_An improved proportionate affine projection algorithm for network echo cancellation        
        % Note: P=1 -> IPNLMS-l1; P=2 -> IPAPA-l1
        aa = 0;
        delta_IPAPA = AF.delta*(1-aa)/(2*length(AF.gTD));
        kd = (1-aa)/(2*length(AF.gTD)) + (1+aa)*abs(AF.gTD)/(AF.delta + 2*sum(abs(AF.gTD)));
        Kd = diag(kd);
        PEM_IPAPA_term = Kd*AF.Lswh_ap*inv(AF.Lswh_ap'*Kd*AF.Lswh_ap + delta_IPAPA*eye(AF.P))*ewh_p;
        AF.gTD = AF.gTD + AF.mu*PEM_IPAPA_term;      
    elseif sel_alg == 2
        % NLMS (no PEMSC)
        aa = 0;
        NLMS_term = AF.TDLLs .* conj(e)/(norm(AF.TDLLs)^2 + AF.delta);
        AF.gTD = AF.gTD + AF.mu * NLMS_term;
    elseif sel_alg == 3        
        % IP-APSA: Improved Proportionate-Affine Projection Signed Alg.
        aa = 0;    % aa=0: IPAPSA; aa= -1: APSA; aa=1: PAPSA
        delta_IPAPA = AF.delta*(1-aa)/(2*length(AF.gTD));
        kd = (1-aa)/(2*length(AF.gTD)) + (1+aa)*abs(AF.gTD)/(AF.delta + 2*sum(abs(AF.gTD)));
        Kd = diag(kd);
        xgs = Kd*AF.Lswh_ap*sign(ewh_p);
%         PEM_IPAPSA_term = xgs/sqrt(norm(xgs)^2 + AF.delta);
        PEM_IPASPA_term = xgs/sqrt(norm(xgs)^2 + delta_IPAPA);
        AF.gTD = AF.gTD + AF.mu*PEM_IPASPA_term; 
    elseif sel_alg == 4
        % MIP-APSA
        aa = 0;        
        delta_IPAPA = AF.delta*(1-aa)/(2*length(AF.gTD));
        kd = (1-aa)/(2*length(AF.gTD)) + (1+aa)*abs(AF.gTD)/(AF.delta + 2*sum(abs(AF.gTD)));
        q0 = kd .* AF.Lswh_ap(:,1);
        AF.Qd = [q0 AF.Qd(:,1:end-1)];     % size (Lf_hatxP)
        xgs = AF.Qd*sign(ewh_p);
%         PEM_MIPASPA_term = xgs/sqrt(norm(xgs)^2 + AF.delta);
        PEM_MIPASPA_term = xgs/sqrt(norm(xgs)^2 + delta_IPAPA);
        AF.gTD = AF.gTD + AF.mu*PEM_MIPASPA_term; 
    elseif sel_alg == 5
        % BS-MIPAPSA
        aa = 0;        
        delta_IPAPA = AF.delta*(1-aa)/(2*length(AF.gTD));
        gTD_part = reshape(AF.gTD,[],AF.M);
        dim_gTD_part = size(gTD_part);
        denom = 0;
        for kk = 1:AF.M
            denom = denom + norm(gTD_part(:,kk));
        end
        denom = 2*AF.M*denom;
        gk = zeros(size(gTD_part));
        for kk = 1:AF.M
            gk(:,kk) = (1-aa)/(2*length(AF.gTD)) + (1+aa)*norm(gTD_part(:,kk))/(AF.delta + denom);
        end
        vgk = reshape(gk,[],1);
        q0 = vgk .* AF.Lswh_ap(:,1);
        AF.Qd = [q0 AF.Qd(:,1:end-1)];     % size (Lf_hatxP)
        xgs = AF.Qd*sign(ewh_p);
%         PEM_IPASPA_term = xgs/sqrt(norm(xgs)^2 + AF.delta);
        PEM_BSMIPASPA_term = xgs/sqrt(norm(xgs)^2 + delta_IPAPA);
        AF.gTD = AF.gTD + AF.mu*PEM_BSMIPASPA_term;
    elseif sel_alg == 6
        % APSA: Affine Projection Signed Alg.
        aa = -1;    % no use for this case; aa=0: IPAPSA; aa= -1: APSA; aa=1: PAPSA
        xgs = AF.Lswh_ap*sign(ewh_p);
        PEM_APSA_term = xgs/sqrt(norm(xgs)^2 + AF.delta);
        AF.gTD = AF.gTD + AF.mu*PEM_APSA_term;
    else          
        % HNLMS: switch NLMS, large mu (when the system is unstable) and PEMSC-NLMS, small mu (when the system is converged)
        aa = 0;
        PEMSC_NLMS_term = AF.TDLLswh .* conj(ep)/(norm(AF.TDLLswh)^2 + AF.delta);
        NLMS_term = AF.TDLLs .* conj(e)/(norm(AF.TDLLs)^2 + AF.delta);
        AF.gTD = AF.gTD + aaa * AF.mu1 * PEMSC_NLMS_term + (1-aaa) * AF.mu2 * NLMS_term;   
        
    end

    
% Remove DC
AF.gTD = AF.gTD - mean(AF.gTD);

end