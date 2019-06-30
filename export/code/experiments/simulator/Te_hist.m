function Te_hist_val=Te_hist(Idr,Iqr,Ids,Iqs,dTeIdr,dTeIds,dTeIqr,dTeIqs,omega_e_base,Lm,Te,poles)
Te_hist_val=-Idr*dTeIdr-Iqs*dTeIqs-Ids*dTeIds-Iqr*dTeIqr;
end
