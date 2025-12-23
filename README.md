## How to Generate Golden for C++ Implementation
```bash
matlab -batch "gen_golden_for_cpp_imp(GoldenGenMode.ImgPar, '../csa-sar-imaging/TestImagingPar/')"
matlab -batch "gen_golden_for_cpp_imp(GoldenGenMode.CsaPar, '../csa-sar-imaging/TestChirpScalingAlgo/golden/')"
matlab -batch "gen_golden_for_cpp_imp(GoldenGenMode.CsaApp, '../csa-sar-imaging/TestChirpScalingAlgo/golden/'"
```