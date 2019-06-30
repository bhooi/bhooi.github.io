function [Ir_fc, Ii_fc] = forecast_var(Ir, Ii, Vr, Vi, temp, pred_len, data_name)
if all(Vi == 0)
    Y = [Ir; Ii; Vr; temp]';
    ynames = {'Ir','Ii','Vr','temp'};
else
    Y = [Ir; Ii; Vr; Vi; temp]';
    ynames = {'Ir','Ii','Vr','Vi','temp'};
end

maxLag=8;
H=pred_len;
[T,nvary]=size(Y);
aicVals=nan(maxLag,1);
for i=1:maxLag
    Xt=[ones(T,1) latMlag(Y,i)];
    % use same number of observations for all estimations
    yt=Y(1+maxLag:end,:);
    xt=Xt(1+maxLag:end,:);

    nobst=size(yt,1);    
    % OLS
    coefft=(xt\yt)';
    residt=yt-(coefft*xt')';

    epe=(residt'*residt)/nobst;
    
    aicVal=aicTest(epe,nvary,i,nobst);
    
    aicVals(i,:)=[aicVal];
end;
[mi,nlag]=min(aicVals);
[y,x,alfa,beta,yhat,resid,sigma2hat,bstd,R2,SS,nobs]=varEst(T,Y,nlag);
yhatF=forecastVARModel([alfa beta]',y,nlag,H,nvary);

Ir_fc = yhatF(:,1)';
Ii_fc = yhatF(:,2)';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [y,x,alfa,beta,yhat,resid,sigma2hat,bstd,R2,SS,nobs]=varEst(T,Y,nlag)

X=[ones(T,1) latMlag(Y,nlag)];
y=Y(1+nlag:end,:);
x=X(1+nlag:end,:);

[nobs,nvary]=size(y);
nvarx=size(x,2);

% OLS
coeff=(x\y)';
beta=coeff(:,2:end);
alfa=coeff(:,1);
yhat=(coeff*x')';
resid=y-yhat;

% ML estimate of covaraince of residuals
Sigma2=(resid'*resid)/nobs;

% Compute some statistics
sige=sqrt(diag((resid'*resid)/(nobs-nvarx)));
bstd=nan(nvary,nvarx);            
sigma2hat=sige(:).^2;
invx=diag(inv(x'*x));
for i=1:nvary 
    bstd(i,:)=sqrt(sigma2hat(i)*invx);            
end;

R2=nan(nvary,1);
m0=eye(nobs)-1/nobs.*ones(nobs);   
ee=diag(resid'*resid);                        
for i=1:nvary                                                 
    R2(i)=1-ee(i)/(y(:,i)'*m0*y(:,i));                        
end;


% Steady state of VAR
% Could alternatively do this by the companion form
%[betac,alfac]=varGetCompForm(beta,alfa,nlag,nvary);
% inv(eye(nlag^2)-betac)*alfac ... and select the nvary first elements
As=0;
for j=1:nlag
    As=As+beta(:,(j-1)*nvary+1:j*nvary);
end
SS=(eye(nvary)-As)\alfa;       


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function yhatF=forecastVARModel(betas,yt,p,H,nvary)

% initial conditioning vector 
ycond = yt(end:-1:end-p+1,:)';
ycond = ycond(:)';
yhatF = nan(H,nvary);

for h=1:H    
    % add the constant to the conditioning information and forecast
    yhatF(h,:) = [ones(1,1) ycond]*betas;    
    % update the conditioning vector with previous periods forecast
    ycond = [yhatF(h,:) ycond(:,1:end-nvary)];    
end