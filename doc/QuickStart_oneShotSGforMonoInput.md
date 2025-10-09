# **Quick-Start Guide for oneShotSGforMonoInput.m**

This document provides instructions on how to use the MATLAB script for single-channel acoustic measurements using the Signal Safeguarding method.

### **English Guide**

#### **1\. Purpose**

This script measures the acoustic impulse response (the "sound" of a room or system) using a special test signal. It performs two main analyses:

1. **Safeguarded (SG):** Plays a pre-processed, "safeguarded" signal and measures the response. This is the primary method.  
2. **Retrospective (Retro-SG):** Plays the original, raw signal and applies the safeguarding concept afterward during analysis.

The script interactively refines the results with your input and then automatically finds the best settings for the retrospective method, saving plots and the final impulse responses as audio files.

#### **2\. Requirements**

* **MATLAB:** Version R2021a or newer is recommended.  
* **Audio Interface:** A microphone and speaker connected to your computer.  
* **A Reference Audio File:** A .wav file to be used as the test signal (e.g., a TSP sweep or white noise).  
* **Script Files:** The following files must be in the same folder:  
  * oneShotSGforMonoInput.m (The main script)  
  * signalSafeguardwithGiantFFTSRC.m (Helper function)  
  * basicPlayRecLoopMono.m (Helper function)

#### **3\. How to Use**

1. **Setup:** Place the three .m files and your reference .wav file into the same directory in MATLAB.  
2. **Run the Script:** Open oneShotSGforMonoInput.m in the MATLAB editor and click the "Run" button, or type oneShotSGforMonoInput in the MATLAB Command Window and press Enter.  
3. **Answer the Initial Prompts:** The script will pause and ask for input in the Command Window:  
   * **Select Reference WAV File:** A file browser will appear. Choose your .wav test signal.  
   * **Enter the safeguarding threshold level (dB):** A good starting point is \-20.  
   * **Enter the high frequency limit for safeguarding (Hz):** Enter the highest frequency you trust in your measurement system (e.g., 20000).  
   * **Select the audio device ID:** A list of available devices will be displayed. Type the number corresponding to your audio interface and press Enter.  
   * **Input plausible length of the impulse response (seconds):** Estimate how long it takes for the sound in your room to die down. 0.5 or 1.0 is a common choice.  
4. **Interactive Refinement:**  
   * After the measurements, a plot will appear. The script will now ask you to define a frequency band to create a clean, final impulse response.  
   * **Enter the desired LOW frequency limit (Hz):** Type a low frequency like 100\.  
   * **Enter the desired HIGH frequency limit (Hz):** Type a high frequency like 18000\.  
   * A new plot will show the refined results. The script will ask: Are these results OK? (Y/N) \[Y\]:. If you are satisfied, press **Enter** (or type Y and press Enter). If not, type N and press Enter to try different frequency limits.  
5. **Automatic Optimization:**  
   * Once you confirm the results, the script will automatically test different settings for the retrospective method to find the best match. This requires no input. A plot showing the error for each setting will be displayed.  
6. **Check the Results:**  
   * All output is saved into a new folder named oneShotSG\_Test\_... (with a timestamp).  
   * Inside this folder, you will find:  
     * .png files for all analysis plots.  
     * refinedImpulseResponse.wav: The final impulse response from the primary (SG) method.  
     * bestImpulseResponseRetro.wav: The final impulse response from the optimized retrospective method.  
     * best\_SG\_params.mat: The optimal parameters found.

### **日本語ガイド (Japanese Guide)**

#### **1\. 目的**

このスクリプトは、音響インパルス応答（部屋やシステムの「音響特性」）を特殊なテスト信号を用いて計測します。主に二つの解析を行います。

1. **セーフガード法 (SG):** 事前に処理された「セーフガード信号」を再生し、その応答を計測します。こちらが主要な手法です。  
2. **レトロスペクティブ法 (Retro-SG):** オリジナルの未処理信号を再生し、解析段階でセーフガードの概念を適用します。

スクリプトは、ユーザーの入力に基づいて対話的に結果を調整し、その後、レトロスペクティブ法に最適な設定を自動で探索します。最終的に、解析プロットとクリーンなインパルス応答を音声ファイルとして保存します。

#### **2\. 必要なもの**

* **MATLAB:** R2021a以降のバージョンを推奨します。  
* **オーディオインターフェース:** PCに接続されたマイクとスピーカー。  
* **参照用音声ファイル:** テスト信号として使用する.wavファイル（TSPスイープやホワイトノイズなど）。  
* **スクリプトファイル:** 以下のファイルをすべて同じフォルダに配置してください。  
  * oneShotSGforMonoInput.m （メインスクリプト）  
  * signalSafeguardwithGiantFFTSRC.m （ヘルパー関数）  
  * basicPlayRecLoopMono.m （ヘルパー関数）

#### **3\. 使い方**

1. **準備:** 3つの.mファイルと参照用の.wavファイルを、MATLABの同じディレクトリに配置します。  
2. **スクリプトの実行:** oneShotSGforMonoInput.mをMATLABエディタで開き、「実行」ボタンをクリックするか、コマンドウィンドウでoneShotSGforMonoInputと入力してEnterキーを押します。  
3. **初期プロンプトへの回答:** スクリプトがコマンドウィンドウで以下の入力を求めます。  
   * **参照WAVファイルの選択:** ファイルブラウザが開きます。テスト信号として使用する.wavファイルを選択してください。  
   * **セーフガードの閾値レベル (dB):** まずは-20などの負の値を入力します。  
   * **セーフガードの高周波上限 (Hz):** 計測システムで信頼できる最も高い周波数を入力します（例: 20000）。  
   * **オーディオデバイスIDの選択:** 利用可能なデバイスのリストが表示されます。再生と録音に使用したいオーディオインターフェースに対応する番号を入力し、Enterキーを押します。  
   * **インパルス応答の想定される長さ (秒):** 部屋の残響が収まるまでのおおよその時間を秒単位で入力します。0.5や1.0が一般的な値です。  
4. **対話的な調整:**  
   * 計測後、プロットが表示されます。次に、最終的なインパルス応答をクリーンにするための周波数帯域を指定するよう求められます。  
   * **下限周波数 (Hz) を入力:** 100などの低い周波数を入力します。  
   * **上限周波数 (Hz) を入力:** 18000などの高い周波数を入力します。  
   * 調整後の結果が新しいプロットで表示されます。コマンドウィンドウにAre these results OK? (Y/N) \[Y\]:と表示されたら、結果に満足した場合は**Enterキー**を押してください（またはYと入力してEnter）。やり直したい場合はNと入力してEnterを押し、再度周波数を設定します。  
5. **自動最適化:**  
   * 対話的な調整が完了すると、スクリプトはレトロスペクティブ法に最も適した設定を自動で探索します。この処理にユーザー入力は不要です。各設定での誤差を示すプロットが表示されます。  
6. **結果の確認:**  
   * すべての出力は、タイムスタンプ付きのoneShotSG\_Test\_...という名前の新しいフォルダに保存されます。  
   * フォルダ内には以下のファイルが生成されます。  
     * 全解析プロットの.pngファイル。  
     * refinedImpulseResponse.wav: 主要法（SG）で得られた最終的なインパルス応答。  
     * bestImpulseResponseRetro.wav: 最適化されたレトロスペクティブ法による最終的なインパルス応答。  
     * best\_SG\_params.mat: 最適化によって見つかったパラメータ。