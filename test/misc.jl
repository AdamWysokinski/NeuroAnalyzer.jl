using NeuroJ
using Test

@test linspace(1, 10, 3) == [1.0, 5.5, 10.0]
@test logspace(log10(2), log10(1000), 10) == [2.0, 3.989473197550056, 7.957948196985135, 15.874010519681994, 31.66446975294948, 63.162276697013205, 125.99210498948727, 251.32106297923613, 501.31932236772616, 1000.0]
@test zero_pad([1 2 3; 4 5 6]) == [1 2 3; 4 5 6; 0 0 0]
@test zero_pad([1 2; 3 4; 5 6]) == [1 2 0; 3 4 0; 5 6 0]
@test vsearch(3, [1, 2, 3, 4, 5, 6], return_distance=true) == (3, 0)
@test vsearch([5.6, 4, 2.9], [1, 2, 3, 4, 5, 6], return_distance=true) == ([6, 4, 3], [0.40000000000000036, 0.0, 0.10000000000000009])
@test cart2pol(1.0, 2.0) == (2.23606797749979, 1.1071487177940904)
@test pol2cart(2.23, 1.10) == (-0.6737363222242237, 0.8695282445762054)
@test generate_window(:hann, 3) == [0.0, 1.0, 0.0]
@test hildebrand_rule([4, 2, 2.2, 4, 5, 6]) == -0.08559209850218256
@test jaccard_similarity([1, 2, 3, 4], [3, 4, 5, 6]) == 0.3333333333333333
@test fft0([1, 2, 3], 2) == [6.0 + 0.0im, -0.8090169943749475 - 3.6654687894677265im, 0.30901699437494745 + 1.6775990443005142im, 0.30901699437494745 - 1.6775990443005142im, -0.8090169943749475 + 3.6654687894677265im]
@test ifft0([6.0 + 0.0im, -0.8090169943749475 - 3.6654687894677265im, 0.30901699437494745 + 1.6775990443005142im, 0.30901699437494745 - 1.6775990443005142im, -0.8090169943749475 + 3.6654687894677265im], 2) == [0.7142857142857142 + 0.0im, 1.3465455503110253 - 0.613691566378193im, 0.8162765370604514 - 0.1790470469817267im, 2.1634173652449578 + 0.6290686482972613im, -0.1540377832141612 + 0.48695893142548385im, 0.7808273556997978 + 0.3343600584725099im, 0.3326852606122141 - 0.6576490248353352im]
@test nextpow2(23) == 32
@test vsplit([1, 2, 3, 4, 5, 6], 2) == [ [1, 4], [2, 5], [3, 6]]
@test rms([1, 2, 3]) == 2.160246899469287
@test generate_sine(2, [1, 2, 3]) == [-4.898587196589413e-16, -9.797174393178826e-16, -1.4695761589768238e-15]
@test freqs(1:10) == ([0.0, 0.1, 0.2, 0.3, 0.4, 0.5], 0.5)
@test freqs([1.1, 2.2, 3.3], 2) == ([0.0, 1.0], 1.0)
@test matrix_sortperm([2 5 1; 8 3 1], rev=false, dims=1) == [1 2 1; 2 1 2]
@test matrix_sort([2 5 1; 8 3 1], [2, 1]; rev=false, dims=1) == [8 3 1; 2 5 1]
@test pad0([1, 2, 3], 3) == [1, 2, 3, 0, 0, 0]
@test hz2rads(42) == 263.89378290154264
@test rads2hz(3.14) == 4.932300466135976
@test z_score([1, 2.3, 3.1, 9.2]) == [-0.7971928077924247, -0.43983051464409645, -0.21991525732204817, 1.4569385797585692]
@test k_categories(22) == (4.69041575982343, 5.325285877609148)
@test cmax([1.2+1.0im, -9.1-4.3im, 1.2+9.11im]) == -9.1 - 4.3im
@test cmin([1.2+1.0im, -9.1-4.3im, 1.2+9.11im]) == 1.2 + 1.0im
@test length(generate_sinc(-1:1:1, f=2)) == 3
@test generate_morlet(2, 2, 2) == [3.2622492927758525e-6, 0.0008200746635147083, 0.04249905628536258, 0.45404073872724515, 1.0, 0.45404073872724515, 0.04249905628536258, 0.0008200746635147083, 3.2622492927758525e-6]
@test generate_gaussian(2, 2, 2) == [0.1353352832366127, 0.32465246735834974, 0.6065306597126334, 0.8824969025845955, 1.0, 0.8824969025845955, 0.6065306597126334, 0.32465246735834974, 0.1353352832366127]
@test sph2cart(10, 10, 10) == (7.040410309066959, 4.564726253638137, -5.440211108893697)

true