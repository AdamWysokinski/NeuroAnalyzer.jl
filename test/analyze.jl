using NeuroAnalyzer
using Test
using Wavelets
using ContinuousWavelets

@info "Initializing"
eeg = import_edf(joinpath(testfiles_path, "eeg-test-edf.edf"))
e10 = epoch(eeg, ep_len=10)
keep_epoch!(e10, ep=1:10)
v = [1, 2, 3, 4, 5]
v1 = [1, 2, 3, 4, 5]
v2 = [6, 5, 4, 3, 2]
m = [1 2 3; 4 5 6]
m1 = [1 2 3; 4 5 6]
m2 = [7 6 5; 4 3 2]
a1 = ones(2, 3, 2)
a2 = zeros(2, 3, 2)

@info "test 1/53: acov()"
@test NeuroAnalyzer.acov(v) == [2.0 0.8 -0.2 -0.8 -0.8;;;]
ac, l = NeuroAnalyzer.acov(e10)
@test size(ac) == (19, 257, 10)
@test length(l) == 257

@info "test 2/53: ampdiff()"
@test size(NeuroAnalyzer.ampdiff(a1)) == (2, 3, 2)
ad = NeuroAnalyzer.ampdiff(e10)
@test size(ad) == (19, 2560, 10)

@info "test 3/53: band_power()"
bp = NeuroAnalyzer.band_power(rand(100), fs=10, f=(1, 2))
@test bp > 0
bp = NeuroAnalyzer.band_power(rand(10, 100, 10), fs=10, f=(1, 2))
@test size(bp) == (10, 10)
@test size(NeuroAnalyzer.band_power(e10, f=(10, 20), mt=false)) == (19, 10)
@test size(NeuroAnalyzer.band_power(e10, f=(10, 20), mt=true)) == (19, 10)

@info "test 4/53: band_mpower()"
@test NeuroAnalyzer.band_mpower(v, fs=10, f=(1, 2)) == (mbp = 0.0, maxfrq = 1.0, maxbp = 0.0)
@test NeuroAnalyzer.band_mpower(a1, fs=10, f=(1, 2)) == (mbp = [0.0 0.0; 0.0 0.0], maxfrq = [1.0 1.0; 1.0 1.0], maxbp = [0.0 0.0; 0.0 0.0])
mbp, maxf, maxbp = NeuroAnalyzer.band_mpower(e10, f=(10, 20), mt=false)
@test size(mbp) == (19, 10)
@test size(maxf) == (19, 10)
@test size(maxbp) == (19, 10)
mbp, maxf, maxbp = NeuroAnalyzer.band_mpower(e10, f=(10, 20), mt=true)
@test size(mbp) == (19, 10)
@test size(maxf) == (19, 10)
@test size(maxbp) == (19, 10)

@info "test 5/53: corm()"
@test NeuroAnalyzer.corm(v) ≈ ones(5, 5)
@test size(NeuroAnalyzer.corm(a1)) == (2, 2, 3, 2)
@test size(NeuroAnalyzer.corm(e10)) == (19, 19, 2560, 10)

@info "test 6/53: covm()"
@test NeuroAnalyzer.covm(v) == [ 2.5  5.0  7.5 10.0 12.5;
                                 5.0 10.0 15.0 20.0 25.0;
                                 7.5 15.0 22.5 30.0 37.5;
                                10.0 20.0 30.0 40.0 50.0;
                                12.5 25.0 37.5 50.0 62.5]
@test size(NeuroAnalyzer.covm(a1)) == (2, 2, 3, 2)
@test size(NeuroAnalyzer.covm(e10)) == (19, 19, 2560, 10)

@info "test 7/53: cps()"
cp, cph, cf = NeuroAnalyzer.cps(rand(10), rand(10), fs=1)
@test length(cp) == 9
@test length(cph) == 9
@test length(cf) == 9
cp, cph, cf = NeuroAnalyzer.cps(rand(10, 10, 2), fs=1)
@test size(cp) == (10, 10, 9, 2) 
@test size(cph) == (10, 10, 9, 2) 
@test length(cf) == 9
cp, cph, cf = NeuroAnalyzer.cps(e10)
@test size(cp) == (19, 19, 2049, 10) 
@test size(cph) == (19, 19, 2049, 10) 
@test length(cf) == 2049
cp, cph, cf = NeuroAnalyzer.cps(rand(10, 10, 2), rand(10, 10, 2), fs=1)
@test size(cp) == (10, 9, 2) 
@test size(cph) == (10, 9, 2) 
@test length(cf) == 180
cp, cph, cf = NeuroAnalyzer.cps(e10, e10, ch1=1:2, ch2=2:3, ep1=1, ep2=1)
@test size(cp) == (2, 2049, 1) 
@test size(cph) == (2, 2049, 1) 
@test length(cf) == 4098

@info "test 8/53: diss()"
@test NeuroAnalyzer.diss(v1, v2) == (gd = 0.21320071635561044, sc = 0.9772727272727273)
@test NeuroAnalyzer.diss(a1) == (gd = [0.0 0.0; 0.0 0.0;;; 0.0 0.0; 0.0 0.0], sc = [1.0 1.0; 1.0 1.0;;; 1.0 1.0; 1.0 1.0])
gd, sc = NeuroAnalyzer.diss(a1, a2)
@test size(gd) == (2, 2)
@test size(sc) == (2, 2)
gd, sc = NeuroAnalyzer.diss(e10)
@test size(gd) == (19, 19, 10)
@test size(sc) == (19, 19, 10)

@info "test 9/53: entropy()"
e, s, l = entropy(rand(10))
@test e < l
@test s < l
e, s, l = entropy(rand(10, 10))
@test size(e) == (10, 1)
@test size(s) == (10, 1)
@test size(l) == (10, 1)
e, s, l = NeuroAnalyzer.entropy(e10)
@test size(e) == (19, 10)
@test size(s) == (19, 10)
@test size(l) == (19, 10)

@info "test 10/53: negentropy()"
n = NeuroAnalyzer.negentropy(rand(10))
@test n < 0
n = NeuroAnalyzer.negentropy(rand(10, 10))
@test size(n) == (10, 1)
n = NeuroAnalyzer.negentropy(eeg)
@test size(n) == (19, 1)

@info "test 11/53: tenv()"
e, t = NeuroAnalyzer.tenv(e10)
@test size(e) == (19, 2560, 10)
@test length(t) == 2560
em, eu, el, t = NeuroAnalyzer.tenv_mean(e10, dims=1)
@test size(em) == (2560, 10)
@test size(eu) == (2560, 10)
@test size(el) == (2560, 10)
@test length(t) == 2560
em, eu, el, t = NeuroAnalyzer.tenv_median(e10, dims=1)
@test size(em) == (2560, 10)
@test size(eu) == (2560, 10)
@test size(el) == (2560, 10)
@test length(t) == 2560

@info "test 12/53: senv()"
e, t = NeuroAnalyzer.senv(e10)
@test size(e) == (19, 37, 10)
@test length(t) == 37
em, eu, el, t = NeuroAnalyzer.senv_mean(e10, dims=1)
@test size(em) == (37, 10)
@test size(eu) == (37, 10)
@test size(el) == (37, 10)
@test length(t) == 37
em, eu, el, t = NeuroAnalyzer.senv_median(e10, dims=1)
@test size(em) == (37, 10)
@test size(eu) == (37, 10)
@test size(el) == (37, 10)
@test length(t) == 37

@info "test 13/53: penv()"
e, t = NeuroAnalyzer.penv(e10)
@test size(e) == (19, 513, 10)
@test length(t) == 513
em, eu, el, t = NeuroAnalyzer.penv_mean(e10, dims=1)
@test size(em) == (513, 10)
@test size(eu) == (513, 10)
@test size(el) == (513, 10)
@test length(t) == 513
em, eu, el, t = NeuroAnalyzer.penv_median(e10, dims=1)
@test size(em) == (513, 10)
@test size(eu) == (513, 10)
@test size(el) == (513, 10)
@test length(t) == 513

@info "test 14/53: henv()"
e, t = NeuroAnalyzer.henv(e10)
@test size(e) == (19, 2560, 10)
@test length(t) == 2560
em, eu, el, t = NeuroAnalyzer.henv_mean(e10, dims=1)
@test size(em) == (2560, 10)
@test size(eu) == (2560, 10)
@test size(el) == (2560, 10)
@test length(t) == 2560
em, eu, el, t = NeuroAnalyzer.henv_median(e10, dims=1)
@test size(em) == (2560, 10)
@test size(eu) == (2560, 10)
@test size(el) == (2560, 10)
@test length(t) == 2560

@info "test 15/53: env_cor()"
ec, p = NeuroAnalyzer.env_cor(e10, e10, ch1=1, ch2=2, ep1=1, ep2=1, type=:amp)
@test ec[1] <= 1.0
@test p[1] <= 1.0
ec, p = NeuroAnalyzer.env_cor(e10, e10, ch1=1, ch2=2, ep1=1, ep2=1, type=:pow)
@test ec[1] <= 1.0
@test p[1] <= 1.0
ec, p = NeuroAnalyzer.env_cor(e10, e10, ch1=1, ch2=2, ep1=1, ep2=1, type=:spec)
@test ec[1] <= 1.0
@test p[1] <= 1.0
ec, p = NeuroAnalyzer.env_cor(e10, e10, ch1=1, ch2=2, ep1=1, ep2=1, type=:hamp)
@test ec[1] <= 1.0
@test p[1] <= 1.0

@info "test 15/53: erp_peaks()"
e = NeuroAnalyzer.erp(e10)
p = NeuroAnalyzer.erp_peaks(e)
@test size(p) == (19, 2)

@info "test 16/53: fcoherence()"
c, msc, f = NeuroAnalyzer.fcoherence(rand(10, 100), fs=10)
@test size(c) == (10, 10, 65)
@test size(msc) == (10, 10, 65)
@test length(f) == 65
c, msc, f = NeuroAnalyzer.fcoherence(rand(10, 100), rand(10, 100), fs=10)
@test length(c) == 65
@test length(msc) == 65
@test length(f) == 65
c, msc, f = NeuroAnalyzer.fcoherence(e10, e10, ch1=1, ch2=2, ep1=1, ep2=1)
@test size(c) == (2049, 1)
@test size(msc) == (2049, 1)
@test length(f) == 2049

@info "test 17/53: frqinst()"
f = NeuroAnalyzer.frqinst(rand(100), fs=10)
@test length(f) == 100
f = NeuroAnalyzer.frqinst(rand(10, 100, 10), fs=10)
@test size(f) == (10, 100, 10)

@info "test 18/53: ged()"
s, r, rn = NeuroAnalyzer.ged(rand(10, 10), rand(10, 10))
@test length(s) == 100
@test length(r) == 10
@test length(rn) == 10
s, r, rn = NeuroAnalyzer.ged(e10, e10)
@test length(s) == 486400
@test length(r) == 190
@test length(rn) == 190

@info "test 19/53: ica()"
ic, ic_mw = NeuroAnalyzer.ica(rand(10, 1000), n=5, tol=1.0)
@test size(ic) == (5, 1000)
@test size(ic_mw) == (10, 5)
ic, ic_mw = NeuroAnalyzer.ica(rand(10, 1000, 10), n=5, tol=1.0)
@test size(ic) == (5, 1000, 10)
@test size(ic_mw) == (10, 5, 10)
ic, ic_mw = NeuroAnalyzer.ica(e10, n=5, tol=1.0)
@test size(ic) == (5, 2560, 10)
@test size(ic_mw) == (24, 5, 10)

@info "test 20/53: ica_reconstruct()"
ic, ic_mw = NeuroAnalyzer.ica(rand(10, 1000), n=5, tol=1.0)
s = NeuroAnalyzer.ica_reconstruct(rand(10, 1000), ic=ic, ic_mw=ic_mw, ic_idx=5)
@test size(s) == (10, 1000)
ic, ic_mw = NeuroAnalyzer.ica(rand(10, 1000, 10), n=5, tol=1.0)
s = NeuroAnalyzer.ica_reconstruct(rand(10, 1000, 10), ic=ic, ic_mw=ic_mw, ic_idx=5)
@test size(s) == (10, 1000, 10)
ic, ic_mw = NeuroAnalyzer.ica(e10, n=5, tol=1.0)
e10_tmp = NeuroAnalyzer.ica_reconstruct(e10, ic, ic_mw; ic_idx=1)
@test size(e10_tmp.data) == (24, 2560, 10)
add_component!(e10, c=:ic, v=ic)
add_component!(e10, c=:ic_mw, v=ic_mw)
e10_tmp = NeuroAnalyzer.ica_reconstruct(e10, ic_idx=1)
@test size(e10_tmp.data) == (24, 2560, 10)

@info "test 21/53: ispc()"
iv, ia, sd, pd, s1p, s2p = NeuroAnalyzer.ispc(v1, v2)
@test iv ≈ 0.6125992852305387
@test ia ≈ -0.0017801930770334254
@test sd == [5, 3, 1, -1, -3]
@test pd ≈ [-1.3157044982273682, 0.8713795327960081, 0.3743702916488456, 0.7615478999167377, -1.0328436072470222]
@test s1p ≈ [1.039406675134543, -0.6027563879589182, -0.21331750626000984, -0.33140501474755424, 0.3279718365439915]
@test s2p ≈ [-0.27629782309282525, 0.26862314483709, 0.16105278538883577, 0.4301428851691834, -0.7048717707030308]
iv, ia = NeuroAnalyzer.ispc(e10)
@test size(iv) == (19, 19, 10)
@test size(ia) == (19, 19, 10)
iv, ia, sd, pd, s1p, s2p = NeuroAnalyzer.ispc(e10, e10, ch1=1, ch2=2, ep1=1, ep2=1)
@test iv ≈ [0.934947546068702;;]
@test ia ≈ [0.0013110745656858525;;]
@test size(sd) == (1, 2560, 1)
@test size(pd) == (1, 2560, 1)
@test size(s1p) == (1, 2560, 1)
@test size(s2p) == (1, 2560, 1)

@info "test 22/53: itpc()"
iv, izv, ia, ip = NeuroAnalyzer.itpc(ones(1, 10, 10), t=1)
@test iv == 1.0
@test izv == 10.0
@test ia == 0.0
@test ip == [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
iv, izv, ia, ip = NeuroAnalyzer.itpc(e10, ch=1, t=256)
@test iv ≈ [0.9742650309891113]
@test izv≈ [9.491923506082141]
@test ia ≈ [-0.09471374965342466]
@test ip[1] ≈ -0.34043930845454473

@info "test 23/53: itpc_spec()"
iv, izv, f = NeuroAnalyzer.itpc_spec(e10, ch=1, frq_lim=(0, 4), frq_n=5)
@test size(iv) == (5, 2560)
@test size(izv) == (5, 2560)
@test f ≈ [0.01, 0.044721359549995794, 0.20000000000000004, 0.8944271909999159, 4.0]

@info "test 24/53: mdiff()"
st, sts, p = NeuroAnalyzer.mdiff(m1, m2, method=:absdiff)
@test length(st) == 6
@test sts == 3.0
@test p in [0.0, 1.0]
st, sts, p = NeuroAnalyzer.mdiff(a1, a2, method=:absdiff)
@test size(st) == (2, 6)
@test sts == [1.0, 1.0]
@test p == [0.0, 0.0]
st, sts, p = NeuroAnalyzer.mdiff(m1, m2, method=:diff2int)
@test length(st) == 6
@test sts == 4.666666666666666
@test p == 1.0 || p == 0.0
st, sts, p = NeuroAnalyzer.mdiff(a1, a2, method=:diff2int)
@test size(st) == (2, 6)
@test sts == [2.0, 2.0]
@test p == [0.0, 0.0]
st, sts, p = NeuroAnalyzer.mdiff(e10, e10, method=:absdiff)
@test size(st) == (10, 57)
@test sts == [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
@test p == [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
st, sts, p = NeuroAnalyzer.mdiff(e10, e10, method=:diff2int)
@test size(st) == (10, 57)
@test sts == [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
@test p == [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

@info "test 25/53: mutual_information()"
@test NeuroAnalyzer.mutual_information(v1, v2) ≈ 0.4199730940219748
@test NeuroAnalyzer.mutual_information(a1) == [0.0 0.0; 0.0 0.0;;; 0.0 0.0; 0.0 0.0]
@test NeuroAnalyzer.mutual_information(a1, a2) == [0.0 0.0; 0.0 0.0] 
m = NeuroAnalyzer.mutual_information(e10)
@test size(m) == (19, 19, 10) 
m = NeuroAnalyzer.mutual_information(e10, e10, ch1=1, ch2=2)
@test size(m) == (1, 10)

@info "test 25/53: msci95()"
@test NeuroAnalyzer.msci95(v1) == (sm = 3.0, ss = 0.7071067811865476, su = 4.385929291125633, sl = 1.6140707088743669)
@test NeuroAnalyzer.msci95(v2) == (sm = 4.0, ss = 0.7071067811865476, su = 5.385929291125633, sl = 2.614070708874367)
@test NeuroAnalyzer.msci95(m1) == (sm = [2.5, 3.5, 4.5], ss = [1.4999999999999998, 1.4999999999999998, 1.4999999999999998], su = [5.4399999999999995, 6.4399999999999995, 7.4399999999999995], sl = [-0.4399999999999995, 0.5600000000000005, 1.5600000000000005])
@test NeuroAnalyzer.msci95(a1) == (sm = [1.0 1.0 1.0; 1.0 1.0 1.0], ss = [0.0 0.0 0.0; 0.0 0.0 0.0], su = [1.0 1.0 1.0; 1.0 1.0 1.0], sl = [1.0 1.0 1.0; 1.0 1.0 1.0])
sm, ss, su, sl = NeuroAnalyzer.msci95(e10)
@test size(sm) == (10, 2560)
@test size(ss) == (10, 2560)
@test size(su) == (10, 2560)
@test size(sl) == (10, 2560)
sm, ss, su, sl = NeuroAnalyzer.msci95(e10, method=:boot)
@test size(sm) == (10, 2560)
@test size(ss) == (10, 2560)
@test size(su) == (10, 2560)
@test size(sl) == (10, 2560)
@test NeuroAnalyzer.msci95(v1, v2) == (sm = -1.0, ss = 1.0, su = 0.96, sl = -2.96)
@test NeuroAnalyzer.msci95(m1, m2) == (sm = [-4.0; 2.0;;], ss = [0.8164965809277261; 0.8164965809277261;;], su = [-2.3996667013816566; 3.6003332986183434;;], sl = [-5.600333298618343; 0.39966670138165683;;])
@test NeuroAnalyzer.msci95(a1, a2) == (sm = [1.0 1.0; 1.0 1.0], ss = [0.0 0.0; 0.0 0.0], su = [1.0 1.0; 1.0 1.0], sl = [1.0 1.0; 1.0 1.0])
sm, ss, su, sl = NeuroAnalyzer.msci95(e10, e10)
@test size(sm) == (19, 10)
@test size(ss) == (19, 10)
@test size(su) == (19, 10)
@test size(sl) == (19, 10)

@info "test 26/53: pca()"
pc, pcv, pcm, pc_model = NeuroAnalyzer.pca(rand(4, 4, 2), n=2)
@test size(pc) == (2, 4, 2)
@test size(pcv) == (2, 2)
@test length(pcm) == 4
pc, pcv, pcm, _ = NeuroAnalyzer.pca(e10, n=4)
@test size(pc) == (4, 2560, 10)
@test size(pcv) == (4, 10)
@test length(pcm) == 24

@info "test 27/53: pca_reconstruct()"
pc, pcv, pcm, pc_model = NeuroAnalyzer.pca(rand(4, 4, 2), n=2)
s = NeuroAnalyzer.pca_reconstruct(rand(4, 4, 2); pc=pc, pc_model=pc_model)
@test size(s) == (4, 4, 2)
pc, pcv, pcm, pc_model = NeuroAnalyzer.pca(e10, n=4)
e10_tmp = add_component(e10, c=:pc, v=pc)
add_component!(e10_tmp, c=:pc_model, v=pc_model)
e10_rec = pca_reconstruct(e10_tmp);
@test size(e10_rec.data) == (24, 2560, 10)
e10_rec = pca_reconstruct(e10_tmp, pc, pc_model);
@test size(e10_rec.data) == (24, 2560, 10)

@info "test 28/53: phdiff()"
@test NeuroAnalyzer.phdiff(a1, avg=:phase, h=true) == zeros(2, 3, 2)
p = NeuroAnalyzer.phdiff(e10, avg=:phase)
@test size(p) == (19, 2560, 10)
p = NeuroAnalyzer.phdiff(e10, avg=:phase)
@test size(p) == (19, 2560, 10)
p = NeuroAnalyzer.phdiff(e10, avg=:phase, h=true)
@test size(p) == (19, 2560, 10)
p = NeuroAnalyzer.phdiff(e10, avg=:phase, h=true)
@test size(p) == (19, 2560, 10)

@info "test 29/53: pli()"
@test pli(v1, v2) == (pv = 0.2, sd = [5, 3, 1, -1, -3], phd = [-1.3157044982273682, 0.8713795327960081, 0.3743702916488456, 0.7615478999167377, -1.0328436072470222], s1ph = [1.039406675134543, -0.6027563879589182, -0.21331750626000984, -0.33140501474755424, 0.3279718365439915], s2ph = [-0.27629782309282525, 0.26862314483709, 0.16105278538883577, 0.4301428851691834, -0.7048717707030308])
pv = NeuroAnalyzer.pli(e10);
@test size(pv) == (19, 19, 10)
pv, sd, phd, s1p, s2p = NeuroAnalyzer.pli(e10, e10, ch1=1, ch2=2, ep1=1, ep2=1)
@test pv == [0.00625;;]
@test size(sd) == (1, 2560, 1)
@test size(phd) == (1, 2560, 1)
@test size(s1p) == (1, 2560, 1)
@test size(s2p) == (1, 2560, 1)

@info "test 30/53: psd()"
p, f = psd(rand(100), fs=10)
@test length(p) == 21
@test f == 0.0:0.25:5.0
p, f = psd(rand(10, 100), fs=10)
@test size(p) == (10, 21)
p, f = psd(rand(10, 100, 10), fs=10)
@test size(p) == (10, 21, 10)
p, f = psd(rand(100), fs=10, mt=true)
@test length(p) == 51
@test round.(f, digits=3) == 0.0:0.1:5.0
p, f = psd(rand(10, 100), fs=10, mt=true)
@test size(p) == (10, 51)
p, f = psd(rand(10, 100, 10), fs=10, mt=true)
@test size(p) == (10, 51, 10)
p, f = NeuroAnalyzer.psd(e10)
@test size(p) == (19, 513, 10)
@test f == 0.0:0.25:128.0
p, f = NeuroAnalyzer.psd(e10, mt=true)
@test size(p) == (19, 1281, 10)
@test round.(f, digits=3) == 0.0:0.1:128.0

@info "test 31/53: psd_mw()"
p, f = psd_mw(rand(100), fs=10, norm=false)
@test length(p) == 6
@test f == [0.1, 1.08, 2.06, 3.04, 4.02, 5.0]
p, f = psd_mw(rand(10, 100), fs=10, norm=false)
@test size(p) == (10, 6)
p, f = psd_mw(rand(10, 100, 10), fs=10, norm=false)
@test size(p) == (10, 6, 10)
p, f = NeuroAnalyzer.psd_mw(e10, frq_lim=(0, 4))
@test size(p) == (19, 5, 10)
@test length(f) == 5

@info "test 32/53: psd_rel()"
p, f = psd_rel(rand(100), fs=10, f=(0, 1))
@test length(p) == 21
@test f == 0.0:0.25:5.0
p, f = psd_rel(rand(10, 100), fs=10, f=(0, 1))
@test size(p) == (10, 21)
p, f = psd_rel(rand(10, 100, 10), fs=10, f=(0, 1))
@test size(p) == (10, 21, 10)
p, f = psd_rel(rand(100), fs=10, mt=true, f=(0, 1))
@test length(p) == 51
@test round.(f, digits=3) == 0.0:0.1:5.0
p, f = psd_rel(rand(10, 100), fs=10, mt=true, f=(0, 1))
@test size(p) == (10, 51)
p, f = psd_rel(rand(10, 100, 10), fs=10, mt=true, f=(0, 1))
@test size(p) == (10, 51, 10)
p, f = NeuroAnalyzer.psd_rel(e10, f=(0, 1))
@test size(p) == (19, 513, 10)
@test f == 0.0:0.25:128.0
p, f = NeuroAnalyzer.psd_rel(e10, mt=true, f=(0, 1))
@test size(p) == (19, 1281, 10)
@test round.(f, digits=3) == 0.0:0.1:128.0

@info "test 33/53: psd_slope()"
lf, ls, pf = psd_slope(rand(100), fs=10)
@test length(lf) == 21
@test pf == 0.0:0.25:5.0
lf, ls, pf = psd_slope(rand(10, 100), fs=10)
@test size(lf) == (10, 21, 1)
@test length(ls) == 10
lf, ls, pf = psd_slope(rand(10, 100, 10), fs=10)
@test size(lf) == (10, 21, 10)
@test size(ls) == (10, 10)
lf, ls, pf = psd_slope(e10)
@test size(lf) == (19, 513, 10)
@test size(ls) == (19, 10)
@test pf == 0.0:0.25:128.0

@info "test 34/53: rms()"
@test NeuroAnalyzer.rms(v1) == 3.3166247903554
@test NeuroAnalyzer.rms(m1) == [2.160246899469287; 5.066228051190222;;]
@test NeuroAnalyzer.rms(a1) == [1.0 1.0; 1.0 1.0]
r = NeuroAnalyzer.rms(e10)
@test size(r) == (19, 10)

@info "test 35/53: rmse()"
@test NeuroAnalyzer.rmse(v1, v2) == 1.0
@test NeuroAnalyzer.rmse(m1, m2) == [0.0; 0.0;;]
@test NeuroAnalyzer.rmse(a1, a2) == [0.0 0.0; 0.0 0.0]
@test NeuroAnalyzer.rmse(e10, e10) == zeros(19, 10)

@info "test 36/53: snr()"
@test NeuroAnalyzer.snr(v1) == 1.8973665961010275
@test NeuroAnalyzer.snr2(v1) == 1.2060453783110545
sn, f = NeuroAnalyzer.snr(e10, type=:rms)
sn, f = NeuroAnalyzer.snr(e10, type=:mean)
@test size(sn) == (19, 1280)
@test length(f) == 1280

@info "test 37/53: spectrogram()"
sp, sf, st = NeuroAnalyzer.spectrogram(e10, method=:standard)
@test size(sp) == (1281, 37, 19, 10)
@test length(sf) == 1281
@test length(st) == 37
sp, sf, st = NeuroAnalyzer.spectrogram(e10, method=:stft)
@test size(sp) == (1281, 37, 19, 10)
@test length(sf) == 1281
@test length(st) == 37
sp, sf, st = NeuroAnalyzer.spectrogram(e10, method=:cwt)
@test size(sp) == (13, 2560, 19, 10)
@test length(sf) == 13
@test length(st) == 2560
sp, sf, st = NeuroAnalyzer.spectrogram(e10, method=:mt)
@test size(sp) == (257, 15, 19, 10)
@test length(sf) == 257
@test length(st) == 15
sp, sf, st = NeuroAnalyzer.spectrogram(e10, method=:mw)
@test size(sp) == (129, 2560, 19, 10)
@test length(sf) == 129
@test length(st) == 2560
sp, sf, st = NeuroAnalyzer.spectrogram(e10, method=:gh)
@test size(sp) == (129, 2560, 19, 10)
@test length(sf) == 129
@test length(st) == 2560

@info "test 38/53: spec_seg()"
sp, sf, st = NeuroAnalyzer.spectrogram(e10, method=:standard)
sp, sst, t, f = spec_seg(sp[:, :, 1, :], sf, st, ch=1, t=(0, 1), f=(0, 10))
@test size(sp) == (37, 11, 1)
@test t == (1, 11)
@test f == (1, 37)
sp, sf, st = NeuroAnalyzer.spectrogram(e10, method=:standard)
sp, sst, t, f = spec_seg(sp, sf, st, ch=1, t=(0, 1), f=(0, 10))
@test size(sp) == (37, 11, 10)
@test t == (1, 11)
@test f == (1, 37)

@info "test 39/53: spectrum()"
c, sa, sp, sph = NeuroAnalyzer.spectrum(rand(100))
@test length(c) == 100
@test length(sa) == 50
@test length(sp) == 50
@test length(sph) == 100
c, sa, sp, sph = NeuroAnalyzer.hspectrum(rand(100))
@test length(c) == 100
@test length(sa) == 100
@test length(sp) == 100
@test length(sph) == 100
c, sa, sp, sph = NeuroAnalyzer.spectrum(rand(10, 100, 10))
@test size(c) == (10, 100, 10)
@test size(sa) == (10, 50, 10)
@test size(sp) == (10, 50, 10)
@test size(sph) == (10, 100, 10)
c, sa, sp, sph = NeuroAnalyzer.hspectrum(rand(10, 100, 10))
@test size(c) == (10, 100, 10)
@test size(sa) == (10, 100, 10)
@test size(sp) == (10, 100, 10)
@test size(sph) == (10, 100, 10)
c, sa, sp, sph = NeuroAnalyzer.spectrum(rand(10, 100, 10), h=true)
@test size(c) == (10, 100, 10)
@test size(sa) == (10, 100, 10)
@test size(sp) == (10, 100, 10)
@test size(sph) == (10, 100, 10)
c, sa, sp, sph = NeuroAnalyzer.spectrum(e10)
@test size(c) == (19, 2560, 10)
@test size(sa) == (19, 1280, 10)
@test size(sp) == (19, 1280, 10)
@test size(sph) == (19, 2560, 10)
c, sa, sp, sph = NeuroAnalyzer.spectrum(e10, h=true)
@test size(c) == (19, 2560, 10)
@test size(sa) == (19, 2560, 10)
@test size(sp) == (19, 2560, 10)
@test size(sph) == (19, 2560, 10)

@info "test 40/53: stationarity()"
s = NeuroAnalyzer.stationarity(e10, method=:adf)
@test size(s) == (24, 2, 10)
s = NeuroAnalyzer.stationarity(e10, method=:cov)
@test size(s) == (257, 10)
s = NeuroAnalyzer.stationarity(e10, method=:hilbert)
@test size(s) == (24, 2559, 10)
s = NeuroAnalyzer.stationarity(e10, method=:mean)
@test size(s) == (24, 10, 10)
s = NeuroAnalyzer.stationarity(e10, method=:var)
@test size(s) == (24, 10, 10)

@info "test 41/53: channel_stats()"
c = NeuroAnalyzer.channel_stats(e10)
for idx in 1:length(c)
    @test size(c[idx]) == (24, 10)
end

@info "test 42/53: epoch_stats()"
e = NeuroAnalyzer.epoch_stats(e10)
for idx in 1:length(e)
    @test length(e[idx]) == 10
end

@info "test 43/53: tcoherence()"
@test NeuroAnalyzer.tcoherence(v1, v2) == (c = [12.0, 0.22360679774997885, -0.22360679774997896, -0.22360679774997896, 0.22360679774997885], msc = [144.0, 0.5236067977499784, 0.07639320225002108, 0.07639320225002108, 0.5236067977499784], ic = [-0.0, -0.6881909602355865, -0.16245984811645328, 0.16245984811645328, 0.6881909602355865])
c, mc, ic = NeuroAnalyzer.tcoherence(rand(10, 100), rand(10, 100))
@test size(c) == (10, 100)
@test size(mc) == (10, 100)
@test size(ic) == (10, 100)
c, mc, ic = NeuroAnalyzer.tcoherence(e10, e10, ch1=1:10, ch2=1:10, ep1=1, ep2=2)
@test size(c) == (10, 2560, 1)
@test size(mc) == (10, 2560, 1)
@test size(ic) == (10, 2560, 1)

@info "test 44/53: tkeo()"
@test NeuroAnalyzer.tkeo(v1) == [1.0, 1.0, 1.0, 1.0, 5.0]
@test NeuroAnalyzer.tkeo(a1) == [1.0 0.0 1.0; 1.0 0.0 1.0;;; 1.0 0.0 1.0; 1.0 0.0 1.0]
t = NeuroAnalyzer.tkeo(e10)
@test size(t) == (19, 2560, 10)

@info "test 45/53: total_power()"
@test NeuroAnalyzer.total_power(rand(100), fs=10) > 0.0
tp = NeuroAnalyzer.total_power(e10)
@test size(tp) == (19, 10)
tp = NeuroAnalyzer.total_power(e10, mt=true)
@test size(tp) == (19, 10)

@info "test 46/53: var_test()"
f, p = NeuroAnalyzer.vartest(e10)
@test size(f) == (19, 19, 10)
@test size(p) == (19, 19, 10)
f, p = NeuroAnalyzer.vartest(e10, e10)
@test size(f) == (19, 19, 10)
@test size(p) == (19, 19, 10)

@info "test 47/53: xcov()"
xc, l = NeuroAnalyzer.xcov(e10, e10, ch1=1, ch2=2, ep1=1, ep2=2)
@test size(xc) == (1, 515, 1)
@test length(l) == 515

@info "test 48/53: xcor()"
xc, l = NeuroAnalyzer.xcor(e10, e10, ch1=1, ch2=2, ep1=1, ep2=2)
@test size(xc) == (1, 515, 1)
@test length(l) == 515

@info "test 49/53: amp_at()"
e = NeuroAnalyzer.erp(e10)
@test size(amp_at(e, t=2)) == (19, 11)

@info "test 50/53: avgamp_at()"
@test size(avgamp_at(e, t=(2, 2.5))) == (19, 11)

@info "test 51/53: maxamp_at()"
@test size(maxamp_at(e, t=(2, 2.5))) == (19, 11)

@info "test 52/53: minamp_at()"
@test size(minamp_at(e, t=(2, 2.5))) == (19, 11)

@info "test 53/53: acor()"
@test NeuroAnalyzer.acor(v) == [1.0 0.4 -0.1 -0.4 -0.4;;;]
ac, l = NeuroAnalyzer.acor(e10)
@test size(ac) == (19, 257, 10)
@test length(l) == 257

true
