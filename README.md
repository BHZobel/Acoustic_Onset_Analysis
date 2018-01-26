# Onset_Finder
AcousticOnsetAnalysis.m is a Matlab function for finding acoustic onsets in an audio file or group of audio files

Benjamin H. Zobel - 01-20-2018
Neurocognition and Perception Laboratory
Department of Psychological and Brain Sciences
University of Massachusetts Amherst

Instructions: 
1. Download all files contained in this package (AcousticOnsetAnalysis.m, amp2dBV.m, PrintOnsetInfo.m, YinBest.m, yin by Alain de Cheveigne.zip) 
2. Unzip 'yin by Alain de Cheveigne.zip' containing all of the required yin functions needed for F0 analysis
3. Make sure Matlab can find all functions contained in this package
3. Run AcousticOnsetsNormAmp.m
4. Follow the prompts. You will be prompted to select the audio files you wish to analyze. You can select one file or multiple files for batch processing.
5. Wait for proccessing
6. A tab-delimited text file will be printed containing the analysis of acoustic onsets

-----------------------------------------------------------------------------------------------------------
NOTES, CITATIONS, AND COPYRIGHT NOTICE FOR YIN:
The yin package contained here was downloaded from http://audition.ens.fr/adc/sw/yin.zip. Yin is a popular F0 estimation algorithm developed by Alain de Cheveigne. The paper on yin, published in JASA (2002), can be downloaded here: http://audition.ens.fr/adc/pdf/2002_JASA_YIN.pdf.

See 'yin.html' for more info.
Version 28 July 2003.

Alain de Cheveigné, CNRS/Ircam, 2002.
Copyright (c) 2002 Centre National de la Recherche Scientifique.

Permission to use, copy, modify, and distribute this software without 
fee is hereby granted FOR RESEARCH PURPOSES only, provided that this
copyright notice appears in all copies and in all supporting 
documentation, and that the software is not redistributed for any 
fee (except for a nominal shipping charge). 

For any other uses of this software, in original or modified form, 
including but not limited to consulting, production or distribution
in whole or in part, specific prior permission must be obtained from CNRS.
Algorithms implemented by this software may be claimed by patents owned 
by CNRS, France Telecom, Ircam or others.

The CNRS makes no representations about the suitability of this 
software for any purpose.  It is provided "as is" without express
or implied warranty.
-----------------------------------------------------------------------------------------------------------
 
